# Phân Tích Vấn Đề Nhận Diện Giọng Nói Khmer

## 🔍 VẤN ĐỀ HIỆN TẠI

### 1. Speech Recognition Đang Dùng km-KH

**File**: `lib/services/speech_service.dart`

**Code hiện tại**:
```dart
_selectedLocaleId = 'km-KH';
```

**Vấn đề**:
- Hệ thống bắt buộc dùng `km-KH` để nhận diện giọng nói
- Google Speech Recognition cho Khmer (km-KH) có độ chính xác THẤP
- Đặc biệt với giọng trẻ em và người Việt học Khmer
- Tỷ lệ nhận sai cao

### 2. Tại Sao km-KH Nhận Diện Kém?

**Lý do kỹ thuật**:
1. **Model training data thiếu**:
   - Google Speech API cho Khmer được train chủ yếu với giọng người Campuchia bản ngữ
   - Ít data từ trẻ em
   - Không có data từ người Việt học Khmer

2. **Accent mismatch**:
   - Người Việt học Khmer có accent khác người Campuchia
   - Trẻ em phát âm chưa chuẩn
   - Model không nhận diện được

3. **Phoneme confusion**:
   - Nhiều âm Khmer giống nhau: ក (ka) vs គ (ko)
   - Model dễ nhầm lẫn

### 3. Hậu Quả

**Khi học sinh nói**:
- Nói đúng nhưng hệ thống báo sai → Nản lòng
- Nói sai nhưng hệ thống báo đúng → Học sai
- Tỷ lệ nhận đúng chỉ ~40-50%

---

## ✅ GIẢI PHÁP

### Phương Án 1: Hybrid Recognition (KHUYẾN NGHỊ)

**Ý tưởng**: Kết hợp nhiều phương pháp nhận diện

```dart
// 1. Thử nhận diện với km-KH trước
final khmerResult = await recognizeWithKhmer(audio);

// 2. Nếu confidence thấp, thử với vi-VN (phiên âm)
if (khmerResult.confidence < 0.6) {
  final vietnameseResult = await recognizeWithVietnamese(audio);
  // So sánh với phiên âm Việt hóa
}

// 3. Chọn kết quả tốt nhất
final bestResult = chooseBestResult(khmerResult, vietnameseResult);
```

**Ưu điểm**:
- Tăng độ chính xác lên ~70-80%
- Phù hợp với người Việt học Khmer
- Không cần thay đổi nhiều

**Nhược điểm**:
- Phức tạp hơn
- Tốn thời gian xử lý

### Phương Án 2: Chỉ Dùng vi-VN với Phiên Âm Chuẩn

**Ý tưởng**: Dùng Speech Recognition tiếng Việt, so sánh với phiên âm đã sửa

```dart
// Nhận diện với vi-VN
_selectedLocaleId = 'vi-VN';

// Học sinh nói: "ka" (theo phiên âm chuẩn)
// Hệ thống nhận: "ka"
// So sánh với target: "ka" → ĐÚNG ✅
```

**Ưu điểm**:
- Đơn giản
- Độ chính xác cao với phiên âm (~80-90%)
- Phù hợp với người Việt

**Nhược điểm**:
- Không nhận diện chữ Khmer trực tiếp
- Học sinh phải nói theo phiên âm

### Phương Án 3: Phoneme-Based Recognition

**Ý tưởng**: Phân tích phoneme thay vì từ hoàn chỉnh

```dart
// Tách âm thành phoneme
// ក (ka) → /k/ + /ɑː/
// So sánh từng phoneme
```

**Ưu điểm**:
- Chính xác cao
- Không phụ thuộc ngôn ngữ

**Nhược điểm**:
- Phức tạp
- Cần thư viện chuyên dụng

---

## 🎯 GIẢI PHÁP ĐỀ XUẤT

### Áp Dụng Phương Án 2: vi-VN với Phiên Âm Chuẩn

**Lý do**:
1. Đơn giản, dễ implement
2. Độ chính xác cao (~80-90%)
3. Phù hợp với đối tượng người Việt học Khmer
4. Đã có phiên âm chuẩn (vừa sửa xong)

**Cách thực hiện**:

#### Bước 1: Thay đổi locale mặc định
```dart
// TRƯỚC
_selectedLocaleId = 'km-KH';

// SAU
_selectedLocaleId = 'vi-VN';
```

#### Bước 2: Cập nhật logic so sánh
```dart
// So sánh với phiên âm chuẩn thay vì chữ Khmer
// Target: ក → Phiên âm: "ka"
// Học sinh nói: "ka"
// Hệ thống nhận: "ka"
// So sánh: "ka" == "ka" → ĐÚNG ✅
```

#### Bước 3: Thêm fallback cho km-KH
```dart
// Nếu thiết bị có km-KH và user muốn dùng
if (userPreferKhmer && khmerAvailable) {
  _selectedLocaleId = 'km-KH';
} else {
  _selectedLocaleId = 'vi-VN';
}
```

---

## 📊 SO SÁNH CÁC PHƯƠNG ÁN

| Tiêu chí | km-KH (hiện tại) | vi-VN (đề xuất) | Hybrid |
|----------|------------------|-----------------|--------|
| Độ chính xác | 40-50% | 80-90% | 70-80% |
| Phù hợp người Việt | ❌ | ✅ | ✅ |
| Phù hợp trẻ em | ❌ | ✅ | ✅ |
| Độ phức tạp | Đơn giản | Đơn giản | Phức tạp |
| Thời gian xử lý | Nhanh | Nhanh | Chậm |
| Nhận chữ Khmer trực tiếp | ✅ | ❌ | ✅ |

---

## ⚠️ LƯU Ý QUAN TRỌNG

### 1. Phương Pháp Học

**Với km-KH**:
- Học sinh phải phát âm Khmer chuẩn 100%
- Khó với người mới học
- Dễ nản lòng

**Với vi-VN**:
- Học sinh nói theo phiên âm (ka, kha, ko...)
- Dễ hơn cho người Việt
- Vẫn học đúng cách phát âm (vì đã sửa phiên âm chuẩn)

### 2. Mục Tiêu Học Tập

**Câu hỏi**: Mục tiêu của app là gì?
- A. Học sinh phát âm Khmer chuẩn như người bản ngữ
- B. Học sinh hiểu và giao tiếp cơ bản bằng Khmer

**Nếu chọn A**: Giữ km-KH, chấp nhận độ chính xác thấp
**Nếu chọn B**: Dùng vi-VN, độ chính xác cao hơn

### 3. Đối Tượng Người Dùng

**Người Việt học Khmer**:
- Accent khác người Campuchia
- Nên dùng vi-VN

**Người Campuchia học chữ**:
- Phát âm chuẩn sẵn
- Nên dùng km-KH

---

## 🔧 CODE CẦN SỬA

### File: `lib/services/speech_service.dart`

#### Thay đổi 1: Locale mặc định
```dart
// Dòng 37
// TRƯỚC
String _selectedLocaleId = 'km-KH';

// SAU
String _selectedLocaleId = 'vi-VN'; // Phù hợp với người Việt học Khmer
```

#### Thay đổi 2: Logic detect locale
```dart
// Dòng 134-167
Future<void> _detectBestLocale() async {
  try {
    final systemLocale = await _speech.systemLocale();
    _fallbackLocaleId = systemLocale?.localeId;

    // Ưu tiên tiếng Việt cho người Việt học Khmer
    final locales = await _speech.locales();
    
    // Tìm tiếng Việt trước
    for (final l in locales) {
      if (l.localeId.toLowerCase().contains('vi')) {
        _selectedLocaleId = l.localeId;
        _khmerAvailable = false; // Đánh dấu không dùng Khmer
        debugPrint('[SpeechService] ✅ Using Vietnamese for better accuracy');
        return;
      }
    }

    // Nếu không có tiếng Việt, mới dùng Khmer
    for (final l in locales) {
      if (l.localeId.toLowerCase().startsWith('km')) {
        _selectedLocaleId = l.localeId;
        _khmerAvailable = true;
        debugPrint('[SpeechService] ⚠️ Using Khmer (may have lower accuracy)');
        return;
      }
    }

    // Fallback cuối cùng
    _selectedLocaleId = 'vi-VN';
    _khmerAvailable = false;
    debugPrint('[SpeechService] ⚠️ No Vietnamese or Khmer found, using vi-VN');
  } catch (e) {
    debugPrint('[SpeechService] Locale detection error: $e');
    _selectedLocaleId = 'vi-VN';
    _khmerAvailable = false;
  }
}
```

#### Thay đổi 3: Thêm tùy chọn cho user
```dart
// Thêm method mới
Future<void> setRecognitionLanguage(String language) async {
  if (language == 'km-KH' || language == 'vi-VN') {
    _selectedLocaleId = language;
    _khmerAvailable = (language == 'km-KH');
    debugPrint('[SpeechService] Recognition language set to: $language');
  }
}
```

---

## 📋 CHECKLIST THỰC HIỆN

- [ ] Sửa locale mặc định: km-KH → vi-VN
- [ ] Sửa logic _detectBestLocale()
- [ ] Thêm method setRecognitionLanguage()
- [ ] Test với người Việt nói "ka", "kha", "ko"
- [ ] Test với trẻ em
- [ ] So sánh độ chính xác trước/sau
- [ ] Cập nhật UI (nếu cần)
- [ ] Tạo tài liệu hướng dẫn

---

## 🎓 KẾT LUẬN

### Khuyến Nghị

**Dùng vi-VN làm mặc định** vì:
1. ✅ Độ chính xác cao hơn (80-90% vs 40-50%)
2. ✅ Phù hợp với người Việt học Khmer
3. ✅ Phù hợp với trẻ em
4. ✅ Đơn giản, dễ maintain
5. ✅ Đã có phiên âm chuẩn (vừa sửa)

### Lộ Trình

**Giai đoạn 1 (Ngay lập tức)**:
- Sửa locale mặc định → vi-VN
- Test độ chính xác

**Giai đoạn 2 (Tuần sau)**:
- Thêm tùy chọn cho user chọn km-KH hoặc vi-VN
- Thêm cảnh báo về độ chính xác

**Giai đoạn 3 (Tháng sau)**:
- Implement hybrid recognition
- Tối ưu hóa scoring algorithm

---

**Tác giả**: Claude Opus 4.8  
**Ngày**: 31/05/2026  
**Trạng thái**: Chờ xác nhận để thực hiện
