# 🔊 HƯỚNG DẪN SỬA LỖI PHÁT ÂM KHMER

## ⚠️ VẤN ĐỀ NGHIÊM TRỌNG

Hiện tại ứng dụng đang sử dụng **Text-to-Speech (TTS)** để phát âm tiếng Khmer, nhưng TTS **KHÔNG CHÍNH XÁC** với nhiều chữ cái, đặc biệt:

- ច (cho)
- ឆ (chhor)
- ជ (cho)
- ឈ (chhor)
- ញ (nhor)

**Hậu quả:** Người học sẽ nghe phát âm SAI và học sai từ đầu!

## ✅ GIẢI PHÁP

Thay thế TTS bằng **file âm thanh chuẩn** do người bản ngữ Khmer ghi âm.

---

## 📋 BƯỚC 1: CHUẨN BỊ FILE ÂM THANH

### 1.1. Tìm người bản ngữ Khmer

- Người Campuchia bản ngữ
- Phát âm chuẩn, rõ ràng
- Không có giọng địa phương quá nặng

### 1.2. Yêu cầu kỹ thuật

- **Format:** MP3
- **Sample rate:** 16kHz hoặc 44.1kHz
- **Channels:** Mono (1 channel)
- **Bitrate:** 128kbps
- **Độ dài:** 0.5-1.5 giây mỗi chữ
- **Chất lượng:** Không có nhiễu nền, tiếng vang
- **Âm lượng:** Chuẩn hóa (normalized)

### 1.3. Danh sách cần ghi âm

#### A. Phụ âm (33 chữ) - ƯU TIÊN CAO

```
Nhóm 1: ក ខ គ ឃ ង
Nhóm 2: ច ឆ ជ ឈ ញ  ⚠️ CỰC KỲ QUAN TRỌNG
Nhóm 3: ដ ឋ ឌ ឍ ណ
Nhóm 4: ត ថ ទ ធ ន
Nhóm 5: ប ផ ព ភ ម
Nhóm 6: យ រ ល វ
Nhóm 7: ស ហ ឡ អ
```

#### B. Nguyên âm (20+ chữ)

```
អា អិ អី អឹ អឺ អុ អូ អួ អើ អឿ
អៀ អេ អែ អៃ អោ អៅ អំ អុំ អះ អាំ
```

#### C. Số (10 chữ)

```
០ ១ ២ ៣ ៤ ៥ ៦ ៧ ៨ ៩
```

---

## 📂 BƯỚC 2: TỔ CHỨC FILE

### 2.1. Cấu trúc thư mục

Tạo cấu trúc sau trong dự án:

```
assets/
└── audio/
    └── khmer/
        ├── consonants/
        │   ├── ka.mp3      # ក
        │   ├── kha.mp3     # ខ
        │   ├── ko.mp3      # គ
        │   ├── kho.mp3     # ឃ
        │   ├── ngo.mp3     # ង
        │   ├── cho.mp3     # ច  ⚠️ QUAN TRỌNG
        │   ├── chhor.mp3   # ឆ  ⚠️ QUAN TRỌNG
        │   ├── cho2.mp3    # ជ  ⚠️ QUAN TRỌNG (khác ច)
        │   ├── chhor2.mp3  # ឈ  ⚠️ QUAN TRỌNG
        │   ├── nhor.mp3    # ញ  ⚠️ QUAN TRỌNG
        │   ├── da.mp3      # ដ
        │   ├── tha.mp3     # ឋ
        │   ├── do.mp3      # ឌ
        │   ├── tho.mp3     # ឍ
        │   ├── na.mp3      # ណ
        │   ├── ta.mp3      # ត
        │   ├── tha2.mp3    # ថ
        │   ├── to.mp3      # ទ
        │   ├── tho2.mp3    # ធ
        │   ├── no.mp3      # ន
        │   ├── ba.mp3      # ប
        │   ├── pha.mp3     # ផ
        │   ├── po.mp3      # ព
        │   ├── pho.mp3     # ភ
        │   ├── mo.mp3      # ម
        │   ├── yo.mp3      # យ
        │   ├── ro.mp3      # រ
        │   ├── lo.mp3      # ល
        │   ├── vo.mp3      # វ
        │   ├── sa.mp3      # ស
        │   ├── ha.mp3      # ហ
        │   ├── la.mp3      # ឡ
        │   └── a.mp3       # អ
        ├── vowels/
        │   ├── aa.mp3      # អា
        │   ├── e.mp3       # អិ
        │   ├── ei.mp3      # អី
        │   └── ...
        └── numbers/
            ├── 0.mp3       # ០
            ├── 1.mp3       # ១
            ├── 2.mp3       # ២
            └── ...
```

### 2.2. Quy tắc đặt tên

- **Chữ thường**, không dấu
- Dùng phiên âm Latin (romanized)
- Nếu 2 chữ có cùng phiên âm, thêm số: `cho.mp3`, `cho2.mp3`

---

## 🔧 BƯỚC 3: CÀI ĐẶT

### 3.1. Cài đặt package

File `pubspec.yaml` đã được cập nhật với:

```yaml
dependencies:
  audioplayers: ^5.2.1  # ✅ Đã thêm
```

Chạy:

```bash
flutter pub get
```

### 3.2. Cấu hình assets

File `pubspec.yaml` đã được cập nhật với:

```yaml
flutter:
  assets:
    - assets/audio/khmer/consonants/
    - assets/audio/khmer/vowels/
    - assets/audio/khmer/numbers/
```

---

## ✅ BƯỚC 4: KIỂM TRA

### 4.1. Chạy script kiểm tra

Tạo file `test/audio_validation_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:khmerkid/services/audio_asset_service.dart';

void main() {
  test('Validate all audio files', () async {
    final service = AudioAssetService.instance;
    await service.init();
    
    final missing = await service.getMissingAudioFiles();
    
    if (missing.isEmpty) {
      print('✅ All audio files are present!');
    } else {
      print('❌ Missing ${missing.length} audio files:');
      for (final file in missing) {
        print('  - $file');
      }
    }
    
    expect(missing.isEmpty, true, reason: 'Some audio files are missing');
  });
}
```

Chạy:

```bash
flutter test test/audio_validation_test.dart
```

### 4.2. Test thủ công

Thêm vào màn hình Settings:

```dart
ElevatedButton(
  onPressed: () async {
    final tts = TtsService.instance;
    await tts.init();
    await tts.validateAudioAssets();
  },
  child: Text('Kiểm tra Audio'),
)
```

---

## 🎯 BƯỚC 5: TRIỂN KHAI

### 5.1. Ưu tiên triển khai

**Giai đoạn 1 (KHẨN CẤP):** 5 chữ bị phát âm sai

```
ច ឆ ជ ឈ ញ
```

**Giai đoạn 2:** 28 phụ âm còn lại

**Giai đoạn 3:** Nguyên âm và số

### 5.2. Cách sử dụng

Code hiện tại **ĐÃ TỰ ĐỘNG** ưu tiên file âm thanh:

```dart
// Tự động dùng file âm thanh nếu có, fallback sang TTS nếu không
await TtsService.instance.speakKhmerLetter(
  character: 'ក',
  pronunciation: 'ka',
  romanized: 'ka',
);
```

---

## 📊 BƯỚC 6: GIÁM SÁT

### 6.1. Log kiểm tra

Khi chạy app, xem log:

```
[TtsService] ✅ Using AUDIO ASSET (100% accurate): ក
[TtsService] ⚠️ Audio asset failed, falling back to TTS
[TtsService] ❌ Character ច is KNOWN to be mispronounced by TTS
[TtsService] ⚠️ CRITICAL: Audio asset missing for ច!
```

### 6.2. Báo cáo

Sau khi triển khai, kiểm tra:

- [ ] Tất cả 33 phụ âm có file âm thanh
- [ ] Tất cả 20+ nguyên âm có file âm thanh
- [ ] Tất cả 10 số có file âm thanh
- [ ] Không có log cảnh báo "Audio asset missing"
- [ ] Người dùng nghe phát âm chính xác

---

## 🚨 LƯU Ý QUAN TRỌNG

### ❌ KHÔNG ĐƯỢC:

1. Dùng TTS cho 5 chữ: ច ឆ ជ ឈ ញ
2. Dùng phát âm Latin thay thế (cho, chhor, ...)
3. Để người học nghe phát âm sai

### ✅ PHẢI:

1. Tìm người bản ngữ ghi âm CHUẨN
2. Kiểm tra kỹ từng file trước khi deploy
3. Test với người Khmer bản ngữ để xác nhận
4. Cập nhật đầy đủ 63 file (33 phụ âm + 20 nguyên âm + 10 số)

---

## 📞 HỖ TRỢ

Nếu cần hỗ trợ tìm người ghi âm hoặc xử lý file âm thanh:

1. Liên hệ cộng đồng Khmer tại Việt Nam
2. Tìm trên Fiverr/Upwork: "Khmer voice recording"
3. Liên hệ trường dạy tiếng Khmer

---

## 📝 CHECKLIST HOÀN THÀNH

- [ ] Đã tìm được người bản ngữ Khmer
- [ ] Đã ghi âm 33 phụ âm (ưu tiên 5 chữ: ច ឆ ជ ឈ ញ)
- [ ] Đã ghi âm 20+ nguyên âm
- [ ] Đã ghi âm 10 số
- [ ] Đã đặt file đúng cấu trúc thư mục
- [ ] Đã chạy `flutter pub get`
- [ ] Đã test validation script
- [ ] Đã test thủ công từng chữ
- [ ] Đã xác nhận với người Khmer bản ngữ
- [ ] Đã deploy lên production

---

**Cập nhật:** 2026-05-31
**Trạng thái:** Đang chờ file âm thanh
**Ưu tiên:** 🔴 KHẨN CẤP
