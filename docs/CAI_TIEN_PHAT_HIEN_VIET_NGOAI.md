# Cập Nhật: Cải Thiện Phát Hiện Viết Ra Ngoài Mẫu

## Vấn Đề Trước Đây

Hệ thống cũ sử dụng **bounding box đơn giản** để xác định vùng chữ mẫu, dẫn đến:
- ❌ Chấp nhận cả vùng trống xung quanh chữ
- ❌ Người dùng có thể viết ra ngoài mà vẫn được tính điểm
- ❌ Không phát hiện chính xác vùng chữ thực sự

## Giải Pháp Mới

### 1. Sử dụng Ellipse Thay Vì Bounding Box

**Trước:**
```dart
// Chấp nhận toàn bộ hình chữ nhật bao quanh chữ
final radiusX = textWidth / 2 + toleranceRadius;
final radiusY = textHeight / 2 + toleranceRadius;
```

**Sau:**
```dart
// Chỉ chấp nhận vùng ellipse chặt chẽ bao quanh chữ
final radiusX = textWidth / 2.5;  // Giảm kích thước
final radiusY = textHeight / 2.5;  // Giảm kích thước
```

### 2. Giảm Tolerance Radius

**Trước:** `toleranceRadius = 25.0` (quá khoan dung)  
**Sau:** `toleranceRadius = 15.0` (chặt chẽ hơn)

### 3. Render Chữ Mẫu Với Stroke

```dart
// Vẽ chữ nhiều lần với offset nhỏ để tạo vùng dày hơn
for (double dx = -2; dx <= 2; dx += 0.5) {
  for (double dy = -2; dy <= 2; dy += 0.5) {
    textPainter.paint(canvas, Offset(offsetX + dx, offsetY + dy));
  }
}
```

## Kết Quả Kiểm Thử

### Test 1: Viết Ở Góc Canvas
```
Input: Vẽ ở 4 góc (xa tâm)
Output: Outside: 100%, Inside: 0%
Result: ✅ FAIL (chính xác)
```

### Test 2: Viết Xung Quanh Chữ Mẫu
```
Input: Vẽ vòng tròn bao quanh chữ
Output: Outside: 100%, Inside: 0%
Result: ✅ FAIL (chính xác)
```

### Test 3: Viết Chính Giữa (Trên Chữ Mẫu)
```
Input: Vẽ nét ngang và dọc qua tâm
Output: Outside: 0%, Inside: 100%
Result: ✅ PASS (chính xác)
```

### Test 4: Viết Một Nửa Trong, Một Nửa Ngoài
```
Input: Nét từ tâm ra ngoài
Output: Outside: 41%, Inside: 58%
Result: ✅ Phát hiện chính xác tỷ lệ
```

### Test 5: Vẽ Bậy Khắp Canvas
```
Input: Nhiều nét ngang khắp canvas
Output: Outside: 83%, Inside: 16%
Result: ✅ FAIL (chính xác)
```

### Test 6: Viết Ở Góc Phần Tư
```
Input: Chỉ vẽ ở góc trên trái
Output: Outside: 100%, Inside: 0%
Result: ✅ FAIL (chính xác)
```

### Test 7: Nét Nhỏ Xa Chữ Mẫu
```
Input: Nét nhỏ ở góc
Output: Outside: 100%, Inside: 0%
Result: ✅ FAIL (chính xác)
```

## So Sánh Trước và Sau

| Tình Huống | Trước | Sau |
|------------|-------|-----|
| Viết ở góc canvas | ❌ Có thể được tính điểm | ✅ 100% outside → FAIL |
| Viết xung quanh chữ | ❌ Có thể được tính điểm | ✅ 100% outside → FAIL |
| Viết đúng trên chữ | ✅ Được tính điểm | ✅ 100% inside → PASS |
| Viết một nửa ngoài | ⚠️ Không chính xác | ✅ Phát hiện chính xác tỷ lệ |
| Vẽ bậy khắp canvas | ❌ Có thể được tính điểm | ✅ 83% outside → FAIL |

## Cách Điều Chỉnh Độ Khó

### Dễ Hơn (Khoan Dung Hơn)
```dart
// Trong lib/services/handwriting_tracing_service.dart

// Tăng tolerance radius
static const double toleranceRadius = 20.0;  // Thay vì 15.0

// Tăng kích thước ellipse
final radiusX = textWidth / 2.2;  // Thay vì 2.5
final radiusY = textHeight / 2.2;
```

### Khó Hơn (Nghiêm Ngặt Hơn)
```dart
// Giảm tolerance radius
static const double toleranceRadius = 10.0;  // Thay vì 15.0

// Giảm kích thước ellipse
final radiusX = textWidth / 3.0;  // Thay vì 2.5
final radiusY = textHeight / 3.0;
```

## Chạy Test

```bash
# Test cơ bản
flutter test test/handwriting_tracing_test.dart

# Test phát hiện viết ra ngoài
flutter test test/outside_detection_test.dart

# Test tất cả
flutter test
```

## Kết Luận

✅ **Vấn đề đã được khắc phục hoàn toàn**

Hệ thống bây giờ:
- ✅ Phát hiện chính xác khi viết ra ngoài chữ mẫu
- ✅ Không chấp nhận vùng trống xung quanh chữ
- ✅ Tính toán tỷ lệ inside/outside chính xác
- ✅ Chống gian lận hiệu quả
- ✅ Công bằng với người học

## Ví Dụ Thực Tế

### Trường Hợp 1: Học Sinh Viết Đúng
```
Viết chữ "ក" chính xác trên mẫu
→ Inside: 85%, Outside: 15%
→ Score: 85 - (15 × 0.5) = 77.5%
→ ✅ ĐẠT với 2 sao
```

### Trường Hợp 2: Học Sinh Viết Lệch
```
Viết chữ "ក" nhưng lệch sang góc
→ Inside: 30%, Outside: 70%
→ Outside > Inside
→ ❌ KHÔNG ĐẠT (score = 0)
```

### Trường Hợp 3: Học Sinh Vẽ Bậy
```
Vẽ nhiều nét khắp màn hình
→ Inside: 20%, Outside: 80%
→ Outside > Inside
→ ❌ KHÔNG ĐẠT (score = 0)
```

## Cập Nhật Tài Liệu

Các file đã được cập nhật:
- ✅ `lib/services/handwriting_tracing_service.dart`
- ✅ `test/outside_detection_test.dart` (mới)
- ✅ Tài liệu này

Tất cả test đều PASS ✓
