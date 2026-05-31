# Làm Rõ: Bài 7 Là Chữ Nào?

## 🔍 PHÂN TÍCH

### Cách Đếm Trong Code

**Theo thứ tự trong `khmer_letter.dart`**:
1. Bài 1: ក (ka)
2. Bài 2: ខ (kha)
3. Bài 3: គ (ko)
4. Bài 4: ឃ (kho)
5. Bài 5: ង (ngo)
6. **Bài 6: 📝 Kiểm tra** (không phải chữ cái)
7. **Bài 7: ច (cha)**
8. **Bài 8: ឆ (chha)** ← Người dùng nói đây là Bài 7

### Cách Đếm Của Người Dùng

**Có thể người dùng đếm không tính bài kiểm tra**:
1. Bài 1: ក (ka)
2. Bài 2: ខ (kha)
3. Bài 3: គ (ko)
4. Bài 4: ឃ (kho)
5. Bài 5: ង (ngo)
6. **Bài 6: ច (cha)**
7. **Bài 7: ឆ (chha)** ← Đây là chữ người dùng nói

---

## ✅ KẾT LUẬN

**Bài 7 theo người dùng = Chữ ឆ (chha)**

### Thông Tin Chữ ឆ

**Dữ liệu hiện tại**:
```dart
KhmerLetter(
  character: 'ឆ',
  romanized: 'chha',
  pronunciation: 'chha',
  meaning: 'con mèo',
)
```

**Phát âm Khmer chuẩn**:
- **IPA**: /cʰɑː/ (a-series, có hơi)
- **Romanization**: chha
- **Phát âm**: "chha" (âm "ch" có hơi + âm "a" dài)
- **Series**: a-series

### Vấn Đề Có Thể

**Khmer TTS có thể đọc sai**:
- ❌ Đọc thành "cha" (nhầm với ច)
- ❌ Đọc thành "chho" (nhầm với ឈ)
- ❌ Không phát âm rõ hơi (aspirated)

---

## ✅ GIẢI PHÁP

**Chữ ឆ đã có trong danh sách problematicChars**:
```dart
final problematicChars = [
  'ច', // cha
  'ឆ', // chha ← ĐÃ CÓ
  'ជ', // cho
  'ឈ', // chho
  'ញ', // nho
];
```

**Nghĩa là**: Chữ ឆ (chha) đã được sửa rồi! ✅

### Cách Hoạt Động

1. Khi phát âm chữ **ឆ**
2. Kiểm tra: có trong problematicChars? → CÓ
3. Bắt buộc dùng fallback: "chha" (tiếng Việt)
4. Không dùng Khmer TTS (vì đọc sai)

---

## 🧪 KIỂM TRA

### Test Chữ ឆ (chha)

**Bước 1**: Mở app
**Bước 2**: Vào bài học chữ ឆ (Bài 7 hoặc Bài 8 tùy cách đếm)
**Bước 3**: Bấm nút "Nghe"
**Bước 4**: Kiểm tra âm thanh

**Kỳ vọng**:
- Nghe "chha" (tiếng Việt)
- Âm "ch" có hơi + âm "a"
- KHÔNG nghe "cha" (không hơi)
- KHÔNG nghe "chho" (âm "o")

### Kiểm Tra Log

**Trong console**:
```
[TtsService] Using fallback for problematic char: ឆ → chha
```

Nếu thấy log này → Đang dùng fallback (đúng) ✅

---

## 📊 TỔNG KẾT

### Trạng Thái

| Chữ | Phiên âm | Trong problematicChars? | Trạng thái |
|-----|----------|-------------------------|------------|
| ច | cha | ✅ CÓ | ✅ Đã sửa |
| ឆ | chha | ✅ CÓ | ✅ Đã sửa |
| ជ | cho | ✅ CÓ | ✅ Đã sửa |
| ឈ | chho | ✅ CÓ | ✅ Đã sửa |
| ញ | nho | ✅ CÓ | ✅ Đã sửa |

**Kết luận**: Chữ ឆ (chha) đã được sửa trong lần cập nhật trước! ✅

---

## ⚠️ NẾU VẪN CÒN VẤN ĐỀ

### Các Khả Năng

1. **Cache chưa clear**:
   - Restart app
   - Clear cache
   - Rebuild app

2. **Phiên âm "chha" vẫn sai**:
   - TTS tiếng Việt đọc "chha" không đúng
   - Cần thử phiên âm khác: "cha ha", "ch-ha"

3. **Cần file âm thanh ghi sẵn**:
   - Giải pháp dài hạn
   - Phát âm chuẩn 100%

### Nếu Vẫn Sai

**Hãy cho biết**:
1. Âm thanh nghe được là gì? (cha, cho, chho, ...)
2. Có thấy log "[TtsService] Using fallback..." không?
3. Thiết bị có cài Khmer TTS không?

---

**Tác giả**: Claude Opus 4.8  
**Ngày**: 31/05/2026  
**Trạng thái**: Chữ ឆ đã được sửa trong problematicChars
