# Phân Tích Vấn Đề Phát Âm Khmer

## 🚨 VẤN ĐỀ NGHIÊM TRỌNG PHÁT HIỆN

### 1. TTS Service Bị Tắt Khmer Cố Ý

**File**: `lib/services/tts_service.dart` (dòng 100-104)

**Code sai**:
```dart
// Ép buộc _khmerSupported = false để ứng dụng luôn dùng giọng đọc tiếng Việt (vi-VN)
_khmerSupported = false;
```

**Hậu quả**:
- ❌ Tắt hoàn toàn giọng Khmer native (km-KH)
- ❌ Bắt buộc dùng giọng Việt (vi-VN) để đọc chữ Khmer
- ❌ Giọng Việt KHÔNG THỂ phát âm đúng chữ Khmer
- ❌ Học sinh nghe phát âm SAI ngay từ đầu

**Đã sửa**:
```dart
// Sử dụng giọng Khmer native nếu thiết bị hỗ trợ
_khmerSupported = matchedKhmer != null;
```

---

## 📊 PHÂN TÍCH DỮ LIỆU PHIÊN ÂM

### Vấn Đề: Phiên Âm Việt Hóa vs Khmer Chuẩn

Dữ liệu hiện tại sử dụng **phiên âm Việt hóa** thay vì **phát âm Khmer chuẩn quốc tế**.

#### Ví Dụ Cụ Thể

| Chữ Khmer | Phiên âm hiện tại (Việt hóa) | Phát âm Khmer chuẩn (IPA) | Romanization chuẩn |
|-----------|------------------------------|---------------------------|-------------------|
| ក | "Co" / "co" | /kɑː/ | ka |
| ខ | "Kho" / "kho" | /kʰɑː/ | kha |
| គ | "Cô" / "cô" | /kɔː/ | ko |
| ឃ | "Khô" / "khô" | /kʰɔː/ | kho |
| ង | "Ngô" / "ngô" | /ŋɔː/ | ngo |
| ច | "Cho" / "cho" | /cɑː/ | cha |
| ឆ | "Chho" / "chho" | /cʰɑː/ | chha |
| ជ | "Chô" / "chô" | /cɔː/ | cho |
| ឈ | "Chhô" / "chhô" | /cʰɔː/ | chho |
| ញ | "Nhô" / "nhô" | /ɲɔː/ | nho |

### Tại Sao Đây Là Vấn Đề?

1. **Phiên âm Việt hóa không chính xác**:
   - "Co" (tiếng Việt) ≠ /kɑː/ (Khmer)
   - "Cô" (tiếng Việt) ≠ /kɔː/ (Khmer)
   - Âm "o" trong tiếng Việt khác hoàn toàn với âm /ɑː/ và /ɔː/ trong Khmer

2. **TTS tiếng Việt không thể phát âm đúng**:
   - Giọng Việt đọc "Co" → âm /ko/ (Việt)
   - Khmer chuẩn phải là /kɑː/ (âm "a" dài, miệng mở rộng)
   - Hoàn toàn khác nhau!

3. **Học sinh học sai từ đầu**:
   - Nghe "co" (Việt) → Bắt chước sai
   - Phát âm sai → Người Khmer không hiểu
   - Mất gốc ngay từ bước đầu

---

## 🎯 HAI PHƯƠNG ÁN GIẢI QUYẾT

### Phương Án 1: Sử Dụng TTS Khmer Native (KHUYẾN NGHỊ)

**Ưu điểm**:
- ✅ Phát âm chuẩn 100%
- ✅ Không cần file âm thanh
- ✅ Dễ bảo trì

**Nhược điểm**:
- ⚠️ Yêu cầu thiết bị có gói ngôn ngữ Khmer
- ⚠️ Không phải thiết bị nào cũng có

**Cách thực hiện**:
1. ✅ Đã sửa: Bật `_khmerSupported = matchedKhmer != null`
2. ✅ Khi có Khmer TTS: Phát chữ Khmer trực tiếp
3. ⚠️ Khi không có: Cần fallback

**Vấn đề còn lại**:
- Khi thiết bị không có Khmer TTS, fallback sang tiếng Việt vẫn sai
- Cần phương án 2 làm fallback

### Phương Án 2: File Âm Thanh Ghi Sẵn (FALLBACK)

**Ưu điểm**:
- ✅ Phát âm chuẩn 100% (do người bản ngữ ghi)
- ✅ Hoạt động trên mọi thiết bị
- ✅ Không phụ thuộc TTS

**Nhược điểm**:
- ⚠️ Cần ghi âm 33 phụ âm + 24 nguyên âm + 10 số + từ vựng
- ⚠️ Tăng kích thước app
- ⚠️ Khó bảo trì khi cập nhật

**Cách thực hiện**:
1. Tạo thư mục `assets/audio/khmer/`
2. Ghi âm từng chữ cái bởi người Khmer bản ngữ
3. Format: MP3 hoặc OGG (nén tốt)
4. Tên file: `consonant_ka.mp3`, `vowel_a.mp3`, `number_0.mp3`
5. Cập nhật `pubspec.yaml`
6. Sửa TtsService để ưu tiên file âm thanh

---

## 📋 DANH SÁCH CẦN GHI ÂM (Nếu Chọn Phương Án 2)

### 33 Phụ Âm
```
ក (ka), ខ (kha), គ (ko), ឃ (kho), ង (ngo)
ច (cha), ឆ (chha), ជ (cho), ឈ (chho), ញ (nho)
ដ (da), ឋ (tha), ឌ (do), ឍ (tho), ណ (na)
ត (ta), ថ (tha), ទ (to), ធ (tho), ន (no)
ប (ba), ផ (pha), ព (po), ភ (pho), ម (mo)
យ (yo), រ (ro), ល (lo), វ (vo)
ស (sa), ហ (ha), ឡ (la), អ (a)
```

### 24 Nguyên Âm
```
អា (a), អិ (e), អី (ei), អឹ (ə), អឺ (əː)
អុ (o), អូ (oː), អួ (uə), អើ (əə), អឿ (ɨə)
អៀ (iə), អេ (e), អែ (ɛ), អៃ (aj), អោ (ao)
អៅ (aw), អំ (ɑm), អុំ (om), អះ (ah), អាំ (am)
អិះ (eh), អុះ (oh), អេះ (eh), អោះ (oah)
```

### 10 Số
```
០ (soun), ១ (muoy), ២ (pii), ៣ (bei), ៤ (buon)
៥ (pram), ៦ (pram muoy), ៧ (pram pii), ៨ (pram bei), ៩ (pram buon)
```

**Tổng**: ~67 file âm thanh cơ bản

---

## 🔧 GIẢI PHÁP TẠM THỜI (NGAY LẬP TỨC)

Vì chưa có file âm thanh ghi sẵn, tôi đề xuất:

### Bước 1: Sửa Phiên Âm Thành Khmer Chuẩn

Thay đổi từ phiên âm Việt hóa sang romanization Khmer chuẩn:

**Trước**:
```dart
KhmerLetter(character: 'ក', romanized: 'Co', pronunciation: 'co')
```

**Sau**:
```dart
KhmerLetter(character: 'ក', romanized: 'ka', pronunciation: 'ka')
```

**Lý do**: 
- Khi có Khmer TTS: Phát chữ Khmer trực tiếp (chuẩn)
- Khi không có: Phát "ka" bằng tiếng Việt (gần đúng hơn "co")

### Bước 2: Thêm Cảnh Báo Cho Người Dùng

Khi thiết bị không có Khmer TTS, hiển thị thông báo:

```
⚠️ Thiết bị chưa cài đặt gói ngôn ngữ Khmer.
Phát âm có thể không chính xác 100%.
Khuyến nghị: Cài đặt gói ngôn ngữ Khmer trong Cài đặt > Ngôn ngữ.
```

### Bước 3: Hướng Dẫn Cài Đặt Khmer TTS

Thêm màn hình hướng dẫn:
- Android: Settings > System > Languages > Add Khmer > Download
- iOS: Settings > General > Keyboard > Keyboards > Add Khmer

---

## 📊 SO SÁNH CÁC PHƯƠNG ÁN

| Tiêu chí | TTS Khmer Native | File Âm Thanh | TTS Việt (hiện tại) |
|----------|------------------|---------------|---------------------|
| Độ chính xác | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ (SAI) |
| Hoạt động mọi thiết bị | ⚠️ (cần cài gói) | ✅ | ✅ |
| Kích thước app | ✅ (nhỏ) | ⚠️ (+5-10MB) | ✅ (nhỏ) |
| Bảo trì | ✅ (dễ) | ⚠️ (khó) | ✅ (dễ) |
| Chi phí phát triển | ✅ (thấp) | ⚠️ (cao - cần ghi âm) | ✅ (thấp) |

---

## ✅ KHUYẾN NGHỊ CUỐI CÙNG

### Giải Pháp Tối Ưu: KẾT HỢP CẢ HAI

1. **Ưu tiên TTS Khmer Native** (đã sửa ✅)
   - Phát âm chuẩn
   - Không tốn dung lượng

2. **Fallback: File Âm Thanh Ghi Sẵn** (cần làm)
   - Khi thiết bị không có Khmer TTS
   - Đảm bảo phát âm chuẩn 100%

3. **Cảnh báo người dùng** (cần làm)
   - Thông báo khi dùng fallback
   - Hướng dẫn cài Khmer TTS

### Lộ Trình Thực Hiện

**Giai đoạn 1 (Ngay lập tức)**: ✅ HOÀN THÀNH
- [x] Sửa TTS Service: Bật Khmer native
- [x] Tạo tài liệu phân tích

**Giai đoạn 2 (Tuần tới)**:
- [ ] Sửa dữ liệu phiên âm: Việt hóa → Khmer chuẩn
- [ ] Thêm cảnh báo khi không có Khmer TTS
- [ ] Thêm hướng dẫn cài đặt Khmer TTS

**Giai đoạn 3 (Tháng tới)**:
- [ ] Ghi âm 67 file âm thanh cơ bản
- [ ] Tích hợp audio player
- [ ] Fallback logic: TTS → Audio → Warning

---

## 🧪 CÁCH KIỂM TRA

### Test 1: Thiết Bị Có Khmer TTS
1. Cài đặt gói ngôn ngữ Khmer
2. Mở app → Bấm nút "Nghe" ở chữ `ក`
3. **Kỳ vọng**: Nghe phát âm Khmer chuẩn /kɑː/

### Test 2: Thiết Bị Không Có Khmer TTS
1. Gỡ gói ngôn ngữ Khmer
2. Mở app → Bấm nút "Nghe" ở chữ `ក`
3. **Hiện tại**: Nghe "co" (tiếng Việt) - SAI
4. **Sau khi sửa phiên âm**: Nghe "ka" (gần đúng hơn)
5. **Sau khi có audio**: Nghe file âm thanh ghi sẵn - CHUẨN

### Test 3: Kiểm Tra Toàn Bộ
- [ ] 33 phụ âm
- [ ] 24 nguyên âm
- [ ] 10 số
- [ ] 330 bài đánh vần
- [ ] Từ vựng

---

## 📚 TÀI LIỆU THAM KHẢO

- [Khmer Alphabet - Wikipedia](https://en.wikipedia.org/wiki/Khmer_alphabet)
- [Khmer Phonology - IPA](https://en.wikipedia.org/wiki/Khmer_phonology)
- [Google TTS Languages](https://cloud.google.com/text-to-speech/docs/voices)
- [Khmer Unicode Standard](https://unicode.org/charts/PDF/U1780.pdf)

---

**Tác giả**: Claude Opus 4.8  
**Ngày**: 31/05/2026  
**Trạng thái**: Đã sửa TTS Service, cần sửa dữ liệu phiên âm
