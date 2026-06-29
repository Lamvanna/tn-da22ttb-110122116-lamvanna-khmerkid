# Audio Assets - Phát âm chuẩn tiếng Khmer

## Cấu trúc thư mục

```
assets/audio/khmer/
├── consonants/     # 33 phụ âm Khmer
├── vowels/         # 20+ nguyên âm Khmer
├── numbers/        # 10 số Khmer (០-៩)
└── words/          # Từ vựng (tùy chọn)
```

## Trạng thái

⚠️ **Thư mục này đang trống - Cần ghi âm file MP3**

## Hướng dẫn

Xem chi tiết tại: `docs/AUDIO_FIX_GUIDE.md`

### Ưu tiên cao nhất (5 file)

Các chữ sau BỊ PHÁT ÂM SAI bởi TTS, cần ghi âm NGAY:

1. `consonants/cho.mp3` - ច
2. `consonants/chhor.mp3` - ឆ
3. `consonants/cho2.mp3` - ជ
4. `consonants/chhor2.mp3` - ឈ
5. `consonants/nhor.mp3` - ញ

### Yêu cầu kỹ thuật

- **Format:** MP3
- **Sample rate:** 16kHz hoặc 44.1kHz
- **Channels:** Mono
- **Bitrate:** 128kbps
- **Độ dài:** 0.5-1.5 giây
- **Chất lượng:** Không nhiễu, người bản ngữ Khmer

## Tạm thời

Hiện tại app sẽ fallback sang TTS khi không có file audio.
Điều này có thể gây phát âm sai cho người học.

**Cần hoàn thành ghi âm trước khi deploy production!**
