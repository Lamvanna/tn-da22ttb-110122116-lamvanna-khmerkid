import 'dart:async';
import 'dart:convert';
import 'dart:io' show NetworkInterface, InternetAddressType, File;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'sync_manager.dart';
import '../data/local/local_database.dart';
import 'handwriting_websocket_client.dart';
import 'connectivity_service.dart';


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

  // Google Sign-In instance (Sử dụng Web Client ID làm serverClientId để lấy idToken trên Android)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '1085311175086-0ka8le871ugi8qr0d0p5rv615qlnca3m.apps.googleusercontent.com',
    serverClientId: '1085311175086-0ka8le871ugi8qr0d0p5rv615qlnca3m.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  static String _activeBaseUrl = 'http://192.168.1.4:5000/api';
  static Future<void>? _detectFuture;

  /// Cổng & đường dẫn API của backend (dùng để ráp URL khi quét mạng)
  static const int _serverPort = 5000;
  static const String _apiPath = '/api';

  /// Timeout dùng chung cho mọi request HTTP — tránh "quay mãi" khi server sai IP
  static const Duration _httpTimeout = Duration(seconds: 12);

  /// Khóa lưu IP server (đã dò được / người dùng nhập tay) trong SharedPreferences
  static const String _kSavedServerUrl = 'saved_server_url';
  static const String _kManualServerUrl = 'manual_server_url';

  /// Danh sách các IP máy chủ dự phòng (Candidate IPs)
  static final List<String> _candidateUrls = [
    'http://192.168.1.4:5000/api', // IP Wi-Fi phòng/nhà hiện tại
    'http://172.20.10.4:5000/api', // IP Wi-Fi Hotspot 4G phát từ điện thoại
    'http://10.0.2.2:5000/api',    // IP máy ảo Android Emulator kết nối với localhost
    'http://localhost:5000/api',   // IP localhost cho Web/PC
  ];

  /// Lấy/đặt IP server do người dùng nhập tay (ưu tiên cao nhất)
  static Future<String?> getManualServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kManualServerUrl);
  }

  /// Đặt IP server thủ công. Truyền IP thô (vd "192.168.1.50") hoặc URL đầy đủ.
  /// Truyền null/rỗng để xóa và quay về tự dò.
  static Future<void> setManualServerUrl(String? ipOrUrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (ipOrUrl == null || ipOrUrl.trim().isEmpty) {
      await prefs.remove(_kManualServerUrl);
      return;
    }
    final normalized = _normalizeUrl(ipOrUrl.trim());
    await prefs.setString(_kManualServerUrl, normalized);
    _activeBaseUrl = normalized;
  }

  /// IP/URL server đang hoạt động (để hiển thị trong màn hình Cài đặt)
  static String get currentServerUrl => _activeBaseUrl;

  /// Tối ưu hóa ảnh Cloudinary động (giảm kích thước, nén chất lượng, chuyển định dạng tự động)
  static String getOptimizedImageUrl(String url, {int width = 200}) {
    if (url.isEmpty || !url.contains('cloudinary.com') || !url.contains('/upload/')) {
      return url;
    }
    return url.replaceFirst('/upload/', '/upload/w_$width,c_limit,q_auto,f_auto/');
  }

  /// Chuẩn hóa input người dùng thành URL API đầy đủ.
  /// "192.168.1.50" → "http://192.168.1.50:5000/api"
  static String _normalizeUrl(String input) {
    var s = input.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    final uri = Uri.parse(s);
    final port = uri.hasPort ? uri.port : _serverPort;
    return '${uri.scheme}://${uri.host}:$port$_apiPath';
  }

  /// Ping một URL /health, trả về true nếu server phản hồi 200.
  static Future<bool> _ping(String url,
      {Duration timeout = const Duration(milliseconds: 900)}) async {
    try {
      final res =
          await http.get(Uri.parse('$url/health')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Tự động dò tìm IP máy chủ đang hoạt động.
  /// Thứ tự ưu tiên: IP nhập tay → IP đã lưu lần trước → danh sách cứng →
  /// quét subnet của thiết bị. Server tìm được sẽ được ghi nhớ.
  static Future<void> detectActiveServer() {
    _detectFuture ??= _detectActiveServerImpl();
    return _detectFuture!;
  }

  static Future<void> _detectActiveServerImpl() async {
    if (kIsWeb) {
      _activeBaseUrl = 'http://localhost:5000/api';
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // 1) IP người dùng nhập tay — ưu tiên cao nhất
    final manual = prefs.getString(_kManualServerUrl);
    if (manual != null && manual.isNotEmpty) {
      _activeBaseUrl = manual;
      if (await _ping(manual, timeout: const Duration(seconds: 2))) {
        debugPrint('✅ [AuthService] Dùng IP thủ công: $manual');
        return;
      }
      debugPrint('⚠️ [AuthService] IP thủ công không phản hồi, thử cách khác: $manual');
    }

    // 2) IP đã lưu từ lần kết nối thành công gần nhất
    final saved = prefs.getString(_kSavedServerUrl);
    final List<String> priority = [
      if (saved != null && saved.isNotEmpty) saved,
      ..._candidateUrls,
    ];

    debugPrint('🔍 [AuthService] Dò tìm IP máy chủ trong danh sách ưu tiên...');
    final found = await _firstResponding(priority, timeout: const Duration(milliseconds: 200));
    if (found != null) {
      _activeBaseUrl = found;
      await prefs.setString(_kSavedServerUrl, found);
      debugPrint('🚀 [AuthService] Đã chọn máy chủ: $_activeBaseUrl');
      return;
    }

    // 3) Quét subnet của thiết bị ở chế độ nền (Background Scan) để không cản trở luồng khởi chạy chính
    debugPrint('🔎 [AuthService] Không thấy trong danh sách — chạy quét subnet nền...');
    _scanLocalSubnet().then((scanned) async {
      if (scanned != null) {
        _activeBaseUrl = scanned;
        final p = await SharedPreferences.getInstance();
        await p.setString(_kSavedServerUrl, scanned);
        debugPrint('🚀 [AuthService] Quét subnet nền tìm thấy máy chủ tại: $_activeBaseUrl');
        // Đồng bộ/Kết nối lại sau khi tìm thấy máy chủ mới
        HandwritingWebSocketClient.instance.connect();
        SyncManager.instance.triggerSync();
      }
    });

    debugPrint('⚠️ [AuthService] Chưa phát hiện server phản hồi nhanh, sử dụng IP mặc định/lần trước: $_activeBaseUrl');
  }

  /// Ping song song nhiều URL, trả về URL phản hồi đầu tiên (hoặc null).
  static Future<String?> _firstResponding(List<String> urls,
      {Duration timeout = const Duration(milliseconds: 900)}) async {
    final completer = Completer<String?>();
    var remaining = urls.length;
    if (remaining == 0) return null;
    for (final url in urls) {
      _ping(url, timeout: timeout).then((ok) {
        if (ok && !completer.isCompleted) {
          completer.complete(url);
        }
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }
    return completer.future;
  }

  /// Quét dải IP cùng subnet với thiết bị để tìm backend.
  /// Suy ra prefix (vd 192.168.1.) từ IP Wi-Fi của máy, ping .1→.254 theo lô.
  static Future<String?> _scanLocalSubnet() async {
    try {
      final prefixes = <String>{};
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address; // vd 192.168.1.23
          final lastDot = ip.lastIndexOf('.');
          if (lastDot > 0) prefixes.add(ip.substring(0, lastDot + 1));
        }
      }
      if (prefixes.isEmpty) return null;

      for (final prefix in prefixes) {
        // Quét theo lô 32 host một lần để không nghẽn mạng (ping timeout 200ms)
        for (var start = 1; start <= 254; start += 32) {
          final batch = <String>[];
          for (var i = start; i < start + 32 && i <= 254; i++) {
            batch.add('http://$prefix$i:$_serverPort$_apiPath');
          }
          final hit = await _firstResponding(batch, timeout: const Duration(milliseconds: 200));
          if (hit != null) return hit;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AuthService] Lỗi quét subnet: $e');
    }
    return null;
  }

  /// Tự động lấy URL máy chủ dựa trên nền tảng thiết bị hoặc IP đã dò tìm
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return _activeBaseUrl;
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

      // Tải thông tin cá nhân mới nhất từ server (nếu thiết bị online)
      bool success = false;
      final isOnline = ConnectivityService.instance.isOnline;
      if (isOnline) {
        // Gắn timeout ngắn (1 giây) khi đăng nhập tự động để không bị kẹt màn hình chào khi mạng yếu hoặc server treo
        success = await fetchProfile(timeout: const Duration(milliseconds: 1000));
      }

      if (!success) {
        // Có 2 trường hợp fetchProfile thất bại hoặc không chạy:
        // 1. Lỗi mạng / server offline (Không kết nối được)
        // 2. Token thực sự hết hạn (Server trả về 401)
        // Hãy kiểm tra xem có kết nối được mạng/server không.
        bool isServerReachable = false;
        if (isOnline) {
          isServerReachable = await _ping(currentServerUrl, timeout: const Duration(milliseconds: 600));
        }

        if (!isServerReachable) {
          // Server không liên lạc được hoặc thiết bị ngoại tuyến, dùng dữ liệu cached offline
          final cachedProfile = prefs.getString('userProfile');
          if (cachedProfile != null) {
            _userProfile = jsonDecode(cachedProfile);
            // Đồng bộ lên StorageService cục bộ
            await _syncProfileToStorage(_userProfile!);
            _isLoading = false;
            notifyListeners();
            // Cho phép vào app chế độ offline
            debugPrint('📶 [AuthService] Thiết bị ngoại tuyến hoặc máy chủ không phản hồi, cho phép Đăng nhập Offline với profile đã lưu.');
            return true;
          }
        }

        // Nếu server hoạt động bình thường nhưng token lỗi, thử refresh token
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          await fetchProfile(timeout: const Duration(milliseconds: 1000));
        } else {
          await logout();
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _isLoading = false;
      notifyListeners();

      // Trigger full sync in background after successful auto login
      SyncManager.instance.fullSync();

      // Kết nối socket.io để lắng nghe thông báo real-time
      HandwritingWebSocketClient.instance.connect();

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
      ).timeout(_httpTimeout);

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
      ).timeout(_httpTimeout);

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

        // Trigger full sync sau khi đăng nhập
        SyncManager.instance.fullSync();

        // Kết nối socket.io để lắng nghe thông báo real-time
        HandwritingWebSocketClient.instance.connect();

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
      ).timeout(_httpTimeout);

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

        // Trigger full sync sau khi đăng nhập Google
        SyncManager.instance.fullSync();

        // Kết nối socket.io để lắng nghe thông báo real-time
        HandwritingWebSocketClient.instance.connect();

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
      
      // Phát hiện lỗi ApiException (Developer Error hoặc Lỗi kết nối mạng) để gửi cờ báo hiệu cho UI đề xuất Mock Login
      final errorStr = e.toString();
      bool isDeveloperError = errorStr.contains('ApiException') ||
                              errorStr.contains('PlatformException') ||
                              errorStr.contains('network_error') ||
                              errorStr.contains('sign_in_failed');

      // Timeout = server sai IP / không kết nối được → hướng dẫn người dùng
      if (e is TimeoutException) {
        return {
          'success': false,
          'message':
              'Không kết nối được máy chủ (quá thời gian chờ). Hãy kiểm tra mạng, '
              'hoặc vào Cài đặt → Kết nối máy chủ để nhập IP / dò tìm lại.',
          'isDeveloperError': false,
          'isTimeout': true,
        };
      }

      return {
        'success': false,
        'message': 'Lỗi đăng nhập Google: $e',
        'isDeveloperError': isDeveloperError,
      };
    }
  }

  /// Đăng nhập bằng tài khoản Google giả lập (Bypass SHA-1 và Client ID cho kiểm thử địa phương)
  Future<Map<String, dynamic>> googleMockLogin({String? email, String? name}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final targetEmail = email ?? 'kietnguyen@gmail.com';
      final targetName = name ?? 'Nguyễn Tuấn Kiệt';
      
      // Tạo idToken giả lập động từ email và tên do người dùng cung cấp (tránh hardcode tài khoản cá nhân trong code)
      final mockToken = 'mock_${targetEmail}_${targetName}_google_1234567890';

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/mobile-signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': mockToken}),
      ).timeout(_httpTimeout);

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

        // Trigger full sync sau khi đăng nhập Mock
        SyncManager.instance.fullSync();

        // Kết nối socket.io để lắng nghe thông báo real-time
        HandwritingWebSocketClient.instance.connect();

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
  Future<bool> fetchProfile({Duration? timeout}) async {
    if (_accessToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(timeout ?? _httpTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final dynamic data = responseData['data']?['user'] ?? responseData['data'];
        
        if (data == null) {
          debugPrint('⚠️ Fetch profile: response data is null');
          return false;
        }

        final Map<String, dynamic> profile = Map<String, dynamic>.from(data);
        
        // Tải thêm thông tin thứ hạng động từ backend MongoDB
        try {
          final rankResponse = await http.get(
            Uri.parse('$baseUrl/users/rank'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_accessToken',
            },
          ).timeout(const Duration(seconds: 3));
          if (rankResponse.statusCode == 200) {
            final rankData = jsonDecode(rankResponse.body);
            final rankVal = rankData['data']?['rank'] ?? 1;
            profile['rank'] = rankVal;
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching rank: $e');
        }

        _userProfile = profile;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userProfile', jsonEncode(profile));

        // Đồng bộ lên StorageService để cập nhật giao diện Trang chủ
        await _syncProfileToStorage(profile);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      return false;
    }
  }

  /// 5.1 Cập nhật thông tin cá nhân (Update Profile)
  Future<bool> updateProfile({String? name, String? avatar}) async {
    if (_accessToken == null) return false;

    try {
      String? remoteAvatarUrl = avatar;
      
      // Nếu avatar là đường dẫn file cục bộ (không bắt đầu bằng http/https), ta cần tải lên Cloudinary trước
      if (avatar != null && !avatar.startsWith('http://') && !avatar.startsWith('https://')) {
        debugPrint('📤 Đang tải ảnh đại diện lên máy chủ: $avatar');
        try {
          final uploadUri = Uri.parse('$baseUrl/upload/image');
          final request = http.MultipartRequest('POST', uploadUri);
          request.headers['Authorization'] = 'Bearer $_accessToken';
          
          final file = File(avatar);
          if (await file.exists()) {
            request.files.add(await http.MultipartFile.fromPath('image', file.path));
            
            final streamedResponse = await request.send().timeout(_httpTimeout);
            final response = await http.Response.fromStream(streamedResponse);
            
            if (response.statusCode == 200 || response.statusCode == 201) {
              final responseData = jsonDecode(response.body);
              final imageUrl = responseData['data']?['imageUrl'] ?? responseData['imageUrl'];
              if (imageUrl != null) {
                remoteAvatarUrl = imageUrl;
                debugPrint('✅ Tải ảnh đại diện thành công. URL: $remoteAvatarUrl');
              } else {
                debugPrint('⚠️ Tải ảnh lên thành công nhưng không thấy link imageUrl trong phản hồi!');
              }
            } else {
              debugPrint('❌ Tải ảnh lên thất bại. Mã trạng thái: ${response.statusCode}, Body: ${response.body}');
            }
          } else {
            debugPrint('❌ File ảnh đại diện cục bộ không tồn tại: $avatar');
          }
        } catch (e) {
          debugPrint('❌ Lỗi xảy ra trong quá trình tải ảnh lên: $e');
        }
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (remoteAvatarUrl != null) body['avatar'] = remoteAvatarUrl;

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(body),
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _userProfile = responseData['data']?['user'] ?? responseData['data'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userProfile', jsonEncode(_userProfile));

        // Đồng bộ lên StorageService để cập nhật giao diện Trang chủ
        if (_userProfile != null) {
          await _syncProfileToStorage(_userProfile!);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      return false;
    }
  }

  /// 5.2 Lấy toàn bộ danh sách huy hiệu từ backend
  Future<List<dynamic>> fetchBadges() async {
    if (_accessToken == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/badges'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching badges: $e');
      return [];
    }
  }

  /// Lấy toàn bộ danh sách nhiệm vụ từ backend
  Future<List<dynamic>> fetchMissions() async {
    if (_accessToken == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/missions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching missions: $e');
      return [];
    }
  }

  /// Nhận phần thưởng của nhiệm vụ
  Future<Map<String, dynamic>> claimMissionReward(String missionId) async {
    if (_accessToken == null) return {'success': false, 'message': 'Chưa đăng nhập'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/missions/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({'missionId': missionId}),
      ).timeout(_httpTimeout);

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Tải lại profile mới nhất để đồng bộ điểm và sao
        await fetchProfile();
        return {'success': true, 'data': responseData['data']};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Lỗi nhận phần thưởng'};
      }
    } catch (e) {
      debugPrint('❌ Error claiming mission reward: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
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
      ).timeout(_httpTimeout);

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
        // Báo cáo đăng xuất lên server (timeout ngắn để không treo UI khi offline)
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        ).timeout(const Duration(seconds: 5));
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

      // Ngắt kết nối socket
      HandwritingWebSocketClient.instance.disconnect();

      // Xóa SharedPreferences local progress bằng StorageService
      try {
        final storage = await StorageService.getInstance();
        await storage.clearAll();
      } catch (e) {
        debugPrint('⚠️ Error clearing SharedPreferences on logout: $e');
      }

      // Xóa cơ sở dữ liệu Isar nội bộ để bảo mật dữ liệu giữa các tài khoản khác nhau
      try {
        await LocalDatabase.instance.clearAll();
      } catch (e) {
        debugPrint('⚠️ Error clearing local database on logout: $e');
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đồng bộ hồ sơ từ Backend sang bộ lưu trữ SharedPreferences nội bộ (cho trang chủ hiển thị)
  Future<void> _syncProfileToStorage(Map<String, dynamic> profile) async {
    try {
      final storage = await StorageService.getInstance();
      await storage.setUsername(profile['name'] ?? 'Bé học giỏi');
      // Backend là nguồn dữ liệu chính (source of truth) cho Stars/XP
      await storage.setStars((profile['stars'] as num?)?.toInt() ?? 0);
      await storage.setXp((profile['xp'] as num?)?.toInt() ?? 0);
      await storage.setStreak(profile['streak'] ?? 0);
      await storage.setAvatarUrl(profile['avatar'] ?? '');

      // Đồng bộ Inventory từ CSDL vào thiết bị
      final inv = profile['inventory'];
      if (inv != null) {
        if (inv['hints'] != null) await storage.setHintsCount((inv['hints'] as num).toInt());
        if (inv['timePowerups'] != null) await storage.setTimeCount((inv['timePowerups'] as num).toInt());
        if (inv['livesPowerups'] != null) await storage.setLivesCount((inv['livesPowerups'] as num).toInt());
        if (inv['doubleScorePowerups'] != null) await storage.setDoubleCount((inv['doubleScorePowerups'] as num).toInt());

        if (inv['hintsLastReg'] != null) await storage.setHintsLastReg((inv['hintsLastReg'] as num).toInt());
        if (inv['timePowerupsLastReg'] != null) await storage.setTimeLastReg((inv['timePowerupsLastReg'] as num).toInt());
        if (inv['livesPowerupsLastReg'] != null) await storage.setLivesLastReg((inv['livesPowerupsLastReg'] as num).toInt());
        if (inv['doubleScorePowerupsLastReg'] != null) await storage.setDoubleLastReg((inv['doubleScorePowerupsLastReg'] as num).toInt());
      }

      // Đồng bộ danh sách vật phẩm đã mua từ CSDL vào thiết bị
      final purchasedItems = profile['purchasedItems'];
      if (purchasedItems != null && purchasedItems is List) {
        await storage.setPurchasedItems(purchasedItems.map((e) => e.toString()).toSet());
      }

      debugPrint('🔄 Đồng bộ profile và inventory từ server lên thiết bị thành công! (Name: ${profile['name']}, Stars: ${profile['stars']}, XP: ${profile['xp']}, Avatar: ${profile['avatar']})');
    } catch (e) {
      debugPrint('⚠️ Error syncing profile to storage: $e');
    }
  }

  /// Cập nhật số sao và XP tạm thời (Optimistic UI Update) ngay khi hoàn thành để tạo cảm giác mượt mà tức thì
  void addStarsAndXpOptimistically(int stars, int xp) {
    if (_userProfile != null) {
      _userProfile!['stars'] = (_userProfile!['stars'] as num? ?? 0).toInt() + stars;
      _userProfile!['xp'] = (_userProfile!['xp'] as num? ?? 0).toInt() + xp;
      
      StorageService.getInstance().then((storage) {
        storage.setStars((_userProfile!['stars'] as num).toInt());
        storage.setXp((_userProfile!['xp'] as num).toInt());
      }).catchError((e) {
        debugPrint('⚠️ Error updating storage optimistically: $e');
      });

      notifyListeners();
    }
  }

  /// Mua vật phẩm trong shop - gọi API backend để trừ sao và lưu vào CSDL
  Future<Map<String, dynamic>> purchaseItem({
    required String itemId,
    required String itemType,
    required int price,
    String? powerUpType,
  }) async {
    if (_accessToken == null) return {'success': false, 'message': 'Chưa đăng nhập'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/purchase-item'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({
          'itemId': itemId,
          'itemType': itemType,
          'price': price,
          'powerUpType': powerUpType,
        }),
      ).timeout(_httpTimeout);

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Cập nhật profile mới nhất để đồng bộ sao và vật phẩm
        await fetchProfile();
        return {'success': true, 'data': responseData['data']};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Lỗi mua vật phẩm'};
      }
    } catch (e) {
      debugPrint('❌ Error purchasing item: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ: $e'};
    }
  }
}
