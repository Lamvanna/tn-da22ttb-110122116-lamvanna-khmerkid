import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

/// Dịch vụ Xác thực người dùng (AuthService) kết nối tới Backend Node.js
class AuthService extends ChangeNotifier {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Tokens & User State
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  // Getters
  String? get accessToken => _accessToken;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _accessToken != null;

  // Google Sign-In instance (Sử dụng Web Client ID làm clientId để lấy idToken trên Android)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '1085311175086-0ka8le871ugi8qr0d0p5rv615qlnca3m.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Tự động lấy URL máy chủ dựa trên nền tảng thiết bị
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    // Sử dụng IP Wi-Fi nội bộ máy tính của bạn (192.168.1.232)
    // Giúp cả điện thoại thật CPH2591 và máy giả lập Android đều kết nối mượt mà
    return 'http://192.168.1.232:5000/api';
  }

  /// 1. Tự động Đăng nhập khi mở App (Auto Login)
  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('accessToken') || !prefs.containsKey('refreshToken')) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _accessToken = prefs.getString('accessToken');
      _refreshToken = prefs.getString('refreshToken');

      // Tải thông tin cá nhân mới nhất từ server
      final success = await fetchProfile();
      if (!success) {
        // Nếu access token hết hạn, thử refresh token
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          await fetchProfile();
        } else {
          await logout();
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Auto login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 2. Đăng ký tài khoản thường (Email & Password)
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Đăng ký thất bại. Vui lòng thử lại.'
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ: $e'};
    }
  }

  /// 3. Đăng nhập tài khoản thường (Email & Password)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;

      if (response.statusCode == 200) {
        _accessToken = responseData['data']['accessToken'];
        _refreshToken = responseData['data']['refreshToken'];
        _userProfile = responseData['data']['user'];

        // Lưu vào bộ nhớ cục bộ
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', _accessToken!);
        await prefs.setString('refreshToken', _refreshToken!);
        await prefs.setString('userProfile', jsonEncode(_userProfile));

        // Đồng bộ lên StorageService nội bộ để cập nhật giao diện Trang chủ ngay lập tức
        await _syncProfileToStorage(_userProfile!);

        notifyListeners();
        return {'success': true, 'message': 'Đăng nhập thành công!'};
      } else {
        notifyListeners();
        return {
          'success': false,
          'message': responseData['message'] ?? 'Tài khoản hoặc mật khẩu không chính xác.'
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  /// 4. Đăng nhập bằng Google (Native Mobile Flow)
  Future<Map<String, dynamic>> googleLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Kích hoạt hộp chọn tài khoản Google của điện thoại
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Hủy đăng nhập Google.'};
      }

      // 2. Lấy thông tin chứng thực từ Google Sign-In
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Không thể lấy Token xác thực từ Google.'};
      }

      // 3. Gửi idToken lên Backend chuyên dụng của chúng ta
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/mobile-signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;

      if (response.statusCode == 200) {
        _accessToken = responseData['data']['accessToken'];
        _refreshToken = responseData['data']['refreshToken'];
        _userProfile = responseData['data']['user'];

        // Lưu local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', _accessToken!);
        await prefs.setString('refreshToken', _refreshToken!);
        await prefs.setString('userProfile', jsonEncode(_userProfile));

        // Đồng bộ lên StorageService để cập nhật giao diện Trang chủ
        await _syncProfileToStorage(_userProfile!);

        notifyListeners();
        return {'success': true, 'message': 'Đăng nhập Google thành công!'};
      } else {
        notifyListeners();
        return {
          'success': false,
          'message': responseData['message'] ?? 'Đăng nhập bằng Google thất bại.'
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      // Phát hiện lỗi ApiException 10 (Developer Error) để gửi cờ báo hiệu cho UI đề xuất Mock Login
      final errorStr = e.toString();
      bool isDeveloperError = errorStr.contains('ApiException: 10') || errorStr.contains('sign_in_failed');

      return {
        'success': false,
        'message': 'Lỗi đăng nhập Google: $e',
        'isDeveloperError': isDeveloperError,
      };
    }
  }

  /// Đăng nhập bằng tài khoản Google giả lập (Bypass SHA-1 và Client ID cho kiểm thử địa phương)
  Future<Map<String, dynamic>> googleMockLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Tạo idToken giả lập theo định dạng mock_email_name_googleId
      const mockToken = 'mock_kietnguyen@gmail.com_Nguyễn Tuấn Kiệt_google_1234567890';

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/mobile-signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': mockToken}),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;

      if (response.statusCode == 200) {
        _accessToken = responseData['data']['accessToken'];
        _refreshToken = responseData['data']['refreshToken'];
        _userProfile = responseData['data']['user'];

        // Lưu local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', _accessToken!);
        await prefs.setString('refreshToken', _refreshToken!);
        await prefs.setString('userProfile', jsonEncode(_userProfile));

        // Đồng bộ lên StorageService để cập nhật giao diện Trang chủ
        await _syncProfileToStorage(_userProfile!);

        notifyListeners();
        return {'success': true, 'message': 'Đăng nhập bằng tài khoản Google giả lập thành công!'};
      } else {
        notifyListeners();
        return {
          'success': false,
          'message': responseData['message'] ?? 'Đăng nhập giả lập thất bại.'
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Lỗi kết nối giả lập: $e'};
    }
  }

  /// 5. Lấy thông tin cá nhân (Profile)
  Future<bool> fetchProfile() async {
    if (_accessToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _userProfile = responseData['data']['user'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userProfile', jsonEncode(_userProfile));

        // Đồng bộ lên StorageService để cập nhật giao diện Trang chủ
        await _syncProfileToStorage(_userProfile!);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      return false;
    }
  }

  /// 6. Làm mới Access Token khi hết hạn (Refresh Token)
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _accessToken = responseData['data']['accessToken'];
        _refreshToken = responseData['data']['refreshToken'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', _accessToken!);
        await prefs.setString('refreshToken', _refreshToken!);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
      return false;
    }
  }

  /// 7. Đăng xuất tài khoản (Logout)
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_accessToken != null) {
        // Báo cáo đăng xuất lên server
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ Server logout report failed: $e');
    } finally {
      // Đăng xuất bên phía Google SDK nếu có
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (_) {}

      // Xóa bộ nhớ đệm
      _accessToken = null;
      _refreshToken = null;
      _userProfile = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userProfile');

      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đồng bộ hồ sơ từ Backend sang bộ lưu trữ SharedPreferences nội bộ (cho trang chủ hiển thị)
  Future<void> _syncProfileToStorage(Map<String, dynamic> profile) async {
    try {
      final storage = await StorageService.getInstance();
      await storage.setUsername(profile['name'] ?? 'Bé học giỏi');
      await storage.setStars(profile['stars'] ?? 0);
      await storage.setXp(profile['xp'] ?? 0);
      await storage.setStreak(profile['streak'] ?? 0);
      await storage.setAvatarUrl(profile['avatar'] ?? '');
      debugPrint('🔄 Đồng bộ profile từ server lên Local Storage thành công! (Name: ${profile['name']}, Stars: ${profile['stars']}, XP: ${profile['xp']}, Avatar: ${profile['avatar']})');
    } catch (e) {
      debugPrint('⚠️ Error syncing profile to storage: $e');
    }
  }
}
