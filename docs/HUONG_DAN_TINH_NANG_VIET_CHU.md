# Tài Liệu Tính Năng Nhận Diện và Chấm Điểm Viết Chữ Theo Mẫu

## Tổng Quan

Hệ thống chấm điểm viết chữ tiếng Khmer dựa trên **độ phủ pixel giữa nét viết và nét mẫu**, không sử dụng OCR hay nhận dạng hình dạng.

## Nguyên Tắc Chấm Điểm

### 1. Tính Toán Độ Phủ

- **Nét Đúng (Inside Coverage)**: % nét viết nằm TRÊN chữ mẫu
- **Nét Sai (Outside Coverage)**: % nét viết nằm NGOÀI chữ mẫu
- **Điểm Cuối Cùng**: Nét Đúng - (Nét Sai × 0.5)

### 2. Điều Kiện Đạt

✅ **Đạt yêu cầu khi:**
- Điểm cuối cùng ≥ 70%
- Nét Đúng > Nét Sai

❌ **Không đạt khi:**
- Nét Sai > Nét Đúng → Điểm = 0 (viết bậy)
- Điểm cuối cùng < 70% → Cần luyện tập thêm

### 3. Xếp Hạng Sao

- ⭐⭐⭐ (3 sao): Điểm ≥ 90%
- ⭐⭐ (2 sao): Điểm ≥ 80%
- ⭐ (1 sao): Điểm ≥ 70%
- Không có sao: Điểm < 70%

## Ví Dụ Cụ Thể

### Trường Hợp 1: Viết Xuất Sắc ⭐⭐⭐
```
Nét đúng: 95%
Nét sai: 5%
Điểm = 95 - (5 × 0.5) = 92.5%
Kết quả: ĐẠT - 3 sao
```

### Trường Hợp 2: Viết Tốt ⭐⭐
```
Nét đúng: 85%
Nét sai: 15%
Điểm = 85 - (15 × 0.5) = 77.5%
Kết quả: ĐẠT - 2 sao
```

### Trường Hợp 3: Viết Khá ⭐
```
Nét đúng: 78%
Nét sai: 22%
Điểm = 78 - (22 × 0.5) = 67%
Kết quả: CHƯA ĐẠT (< 70%)
Lời khuyên: "Cố gắng viết sát hơn với nét mẫu"
```

### Trường Hợp 4: Viết Sai (Vẽ Bậy)
```
Nét đúng: 40%
Nét sai: 60%
Kết quả: KHÔNG ĐẠT (nét sai > nét đúng)
Điểm = 0
Lời khuyên: "Hãy viết chính xác theo nét mẫu màu xanh"
```

## Phản Hồi Trực Quan

Sau khi kiểm tra, hệ thống hiển thị nét viết với màu sắc:

- 🟢 **Màu Xanh**: Nét viết đúng trên chữ mẫu
- 🟡 **Màu Vàng**: Nét viết gần đúng (trong vùng chấp nhận)
- 🔴 **Màu Đỏ**: Nét viết sai, nằm ngoài chữ mẫu

## Cấu Trúc Kỹ Thuật

### File Chính

1. **lib/services/handwriting_tracing_service.dart**
   - Service chấm điểm chính
   - Tạo bitmap chữ mẫu
   - Phân tích nét viết
   - Tạo phản hồi trực quan

2. **lib/screens/learn/writing_detail_screen.dart**
   - Giao diện tập viết
   - Canvas vẽ chữ
   - Hiển thị phản hồi màu sắc

3. **lib/services/scoring_service.dart**
   - Tích hợp với hệ thống cũ
   - Duy trì tương thích ngược

### Thuật Toán

```
1. Tạo lưới 64×64 đại diện cho chữ mẫu
2. Với mỗi điểm trong nét viết của người dùng:
   - Kiểm tra điểm nằm trong/gần/ngoài chữ mẫu
   - Đếm số điểm mỗi loại
3. Tính % nét đúng và % nét sai
4. Áp dụng công thức: Điểm = Nét Đúng - (Nét Sai × 0.5)
5. Kiểm tra điều kiện đạt/không đạt
6. Tạo phản hồi và lời khuyên
```

## Cấu Hình Tham Số

Có thể điều chỉnh các tham số trong `HandwritingTracingService`:

```dart
static const double strokeWidth = 4.0;           // Độ dày nét vẽ
static const double templateStrokeWidth = 180.0; // Kích thước font chữ mẫu
static const double toleranceRadius = 25.0;      // Bán kính chấp nhận "gần đúng"
static const double passThreshold = 70.0;        // Ngưỡng điểm đạt
static const int gridResolution = 64;            // Độ phân giải lưới
```

### Hướng Dẫn Điều Chỉnh

- **Tăng `toleranceRadius`**: Dễ dàng hơn (chấp nhận nét xa hơn)
- **Giảm `passThreshold`**: Dễ đạt hơn (ví dụ: 60% thay vì 70%)
- **Tăng `gridResolution`**: Chính xác hơn nhưng chậm hơn
- **Điều chỉnh hệ số phạt**: Hiện tại là 0.5 (phạt 50% nét sai)

## Kiểm Thử

Chạy test để kiểm tra:

```bash
flutter test test/handwriting_tracing_test.dart
```

Kết quả mong đợi:
```
✓ Empty strokes should return 0 score
✓ Strokes completely outside template should fail
✓ Strokes in center should have high inside coverage
✓ Score >= 70% should pass
✓ Outside coverage > inside coverage should fail
✓ Star rating should match score ranges
✓ Visual feedback should be generated
✓ Different characters should work
✓ Feedback messages should be appropriate
✓ Tips should be helpful based on performance

All tests passed! ✓
```

## Ưu Điểm Của Hệ Thống

✅ **Chống gian lận**: Không thể đạt điểm cao bằng cách vẽ bậy
✅ **Công bằng**: Chấm điểm dựa trên độ chính xác thực tế
✅ **Trực quan**: Phản hồi màu sắc giúp học sinh hiểu lỗi sai
✅ **Linh hoạt**: Có thể điều chỉnh độ khó dễ dàng
✅ **Hiệu quả**: Xử lý nhanh, không cần kết nối mạng
✅ **Đầy đủ**: Hoạt động với tất cả chữ cái tiếng Khmer

## Cách Sử Dụng Trong Code

### Chấm Điểm Viết Chữ

```dart
final result = HandwritingTracingService.instance.scoreTracing(
  character: 'ក',
  userStrokes: _strokes,
  canvasSize: Size(400, 400),
);

print('Điểm: ${result.finalScore}%');
print('Nét đúng: ${result.insideCoverage}%');
print('Nét sai: ${result.outsideCoverage}%');
print('Đạt: ${result.passed}');
print('Sao: ${result.stars}');
print('Phản hồi: ${result.feedback}');
```

### Hiển Thị Phản Hồi Trực Quan

```dart
// Trong CustomPainter
for (final segment in result.visualFeedback) {
  final paint = Paint()
    ..color = segment.color  // Green, Yellow, or Red
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round;
  
  // Vẽ segment
  canvas.drawPath(createPath(segment.points), paint);
}
```

## Xử Lý Sự Cố

### Vấn Đề: Điểm quá thấp dù viết tốt
**Giải pháp**: Tăng `toleranceRadius` từ 25.0 lên 30.0 hoặc 35.0

### Vấn Đề: Học sinh vẽ bậy vẫn đạt điểm
**Giải pháp**: Kiểm tra logic "nét sai > nét đúng" đã hoạt động chưa

### Vấn Đề: Chữ mẫu không khớp với font
**Giải pháp**: Điều chỉnh `templateStrokeWidth` để khớp với kích thước hiển thị

### Vấn Đề: Không hiển thị màu phản hồi
**Giải pháp**: Kiểm tra `_showFeedback = true` sau khi chấm điểm

## Tính Năng Tương Lai

### Cải Tiến Có Thể Thêm

1. **Kiểm tra thứ tự nét**: Đảm bảo viết đúng thứ tự
2. **Phản hồi thời gian thực**: Hiển thị màu ngay khi đang vẽ
3. **Hướng dẫn động**: Hiển thị animation cách viết đúng
4. **Độ khó tự động**: Điều chỉnh theo độ tuổi/trình độ
5. **Machine Learning**: Học từ dữ liệu thực tế của người dùng

## Kết Luận

Hệ thống chấm điểm viết chữ này cung cấp:

- ✅ Chấm điểm chính xác dựa trên độ phủ nét
- ✅ Chống gian lận hiệu quả
- ✅ Phản hồi trực quan dễ hiểu
- ✅ Hoạt động với mọi chữ cái tiếng Khmer
- ✅ Có thể tùy chỉnh linh hoạt
- ✅ Đã được kiểm thử đầy đủ

Hệ thống ưu tiên độ chính xác và công bằng, đồng thời đủ khoan dung cho trẻ em đang học viết.
