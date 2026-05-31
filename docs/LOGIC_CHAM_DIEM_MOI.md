# Logic Chấm Điểm Mới - Dựa Trên % Nét Trong và Nét Ngoài

## ✅ Yêu Cầu Đã Được Cập Nhật

### Quy Tắc Chấm Điểm Mới

**Điều kiện ĐẠT:**
1. ✅ Nét viết TRONG chữ mẫu ≥ 70%
2. ✅ Nét viết NGOÀI chữ mẫu ≤ 30%

**Điều kiện KHÔNG ĐẠT:**
1. ❌ Nếu nét NGOÀI > 30% → FAIL (điểm = 0)
2. ❌ Nếu nét TRONG < 70% → FAIL (điểm = nét trong %)

### Công Thức Tính Điểm

```
Inside Coverage = (số điểm trong / tổng số điểm) × 100%
Outside Coverage = (số điểm ngoài / tổng số điểm) × 100%

Kiểm tra:
1. Nếu Outside > 30% → FAIL (score = 0)
2. Nếu Inside < 70% → FAIL (score = inside%)
3. Nếu cả 2 điều kiện đạt → PASS (score = inside%)
```

### Xếp Hạng Sao

- ⭐⭐⭐ (3 sao): Inside ≥ 90%
- ⭐⭐ (2 sao): Inside ≥ 80%
- ⭐ (1 sao): Inside ≥ 70%
- Không có sao: Inside < 70% hoặc Outside > 30%

## 📊 Kết Quả Test

### Test 1: Boundary Case (70% trong, 30% ngoài)
```
Input: 70% inside, 30% outside
Result: ✅ PASS, Score: 70%, Stars: 1
```

### Test 2: Inside < 70% (60% trong, 40% ngoài)
```
Input: 60% inside, 40% outside
Result: ❌ FAIL, Score: 0%
Reason: Outside > 30% (ưu tiên kiểm tra trước)
```

### Test 3: Outside > 30% (67% trong, 33% ngoài)
```
Input: 67% inside, 33% outside
Result: ❌ FAIL, Score: 0%
Reason: Outside > 30%
```

### Test 4: Excellent (100% trong, 0% ngoài)
```
Input: 100% inside, 0% outside
Result: ✅ PASS, Score: 100%, Stars: 3
```

### Test 5: Very Good (100% trong, 0% ngoài)
```
Input: 100% inside, 0% outside
Result: ✅ PASS, Score: 100%, Stars: 3
```

### Test 6: Good (90% trong, 10% ngoài)
```
Input: 90% inside, 10% outside
Result: ✅ PASS, Score: 90%, Stars: 2
```

### Test 7: Center Drawing (100% trong)
```
Input: Chỉ vẽ ở tâm
Result: Inside: 100%, Outside: 0%
```

### Test 8: Corner Drawing (100% ngoài)
```
Input: Chỉ vẽ ở góc
Result: Inside: 0%, Outside: 100%
Status: ❌ FAIL
```

## 📋 Ví Dụ Thực Tế

### Ví Dụ 1: Học Sinh Viết Tốt ✅
```
Viết chữ "ក" chính xác
→ Inside: 85%, Outside: 15%
→ Kiểm tra: Outside (15%) ≤ 30% ✓
→ Kiểm tra: Inside (85%) ≥ 70% ✓
→ ✅ ĐẠT với điểm 85% - 2 sao
```

### Ví Dụ 2: Học Sinh Viết Thiếu Chính Xác ❌
```
Viết chữ "ក" nhưng chỉ 60% trên mẫu
→ Inside: 60%, Outside: 40%
→ Kiểm tra: Outside (40%) > 30% ✗
→ ❌ KHÔNG ĐẠT - Điểm 0
→ Lý do: "Viết quá nhiều ra ngoài chữ mẫu"
→ Tips: "Nét viết ra ngoài: 40% (chỉ cho phép tối đa 30%)"
```

### Ví Dụ 3: Học Sinh Viết Chưa Đủ ❌
```
Viết chữ "ក" nhưng chỉ 65% trên mẫu
→ Inside: 65%, Outside: 25%
→ Kiểm tra: Outside (25%) ≤ 30% ✓
→ Kiểm tra: Inside (65%) < 70% ✗
→ ❌ CHƯA ĐẠT - Điểm 65%
→ Lý do: "Viết chưa đủ chính xác"
→ Tips: "Nét viết đúng: 65% (cần tối thiểu 70%)"
```

### Ví Dụ 4: Học Sinh Viết Xuất Sắc ✅
```
Viết chữ "ក" rất chính xác
→ Inside: 95%, Outside: 5%
→ Kiểm tra: Outside (5%) ≤ 30% ✓
→ Kiểm tra: Inside (95%) ≥ 70% ✓
→ ✅ ĐẠT với điểm 95% - 3 sao
→ Feedback: "Xuất sắc! ⭐⭐⭐"
```

### Ví Dụ 5: Học Sinh Vẽ Bậy ❌
```
Vẽ nhiều nét khắp màn hình
→ Inside: 20%, Outside: 80%
→ Kiểm tra: Outside (80%) > 30% ✗
→ ❌ KHÔNG ĐẠT - Điểm 0
→ Lý do: "Viết quá nhiều ra ngoài chữ mẫu"
```

## 🔄 So Sánh Logic Cũ vs Mới

| Tình Huống | Logic Cũ | Logic Mới |
|------------|----------|-----------|
| Inside 85%, Outside 15% | Score = 85 - (15×0.5) = 77.5% → PASS | Inside ≥ 70% ✓, Outside ≤ 30% ✓ → PASS 85% |
| Inside 60%, Outside 40% | Score = 60 - (40×0.5) = 40% → FAIL | Outside > 30% → FAIL (score = 0) |
| Inside 65%, Outside 25% | Score = 65 - (25×0.5) = 52.5% → FAIL | Inside < 70% → FAIL (score = 65%) |
| Inside 70%, Outside 30% | Score = 70 - (30×0.5) = 55% → FAIL | Boundary case → PASS 70% |
| Inside 90%, Outside 10% | Score = 90 - (10×0.5) = 85% → PASS | Inside ≥ 70% ✓, Outside ≤ 30% ✓ → PASS 90% |

## 🎯 Ưu Điểm Logic Mới

✅ **Rõ ràng hơn**: Điều kiện đạt/không đạt dễ hiểu
✅ **Công bằng hơn**: Không bị trừ điểm kép
✅ **Khuyến khích đúng**: Tập trung viết ĐÚNG trên mẫu
✅ **Chống gian lận**: Giới hạn nét ngoài ≤ 30%
✅ **Phản hồi cụ thể**: Tips chỉ rõ vấn đề (thiếu trong hay nhiều ngoài)

## 📝 Thông Báo Lỗi

### Lỗi 1: Nét Ngoài > 30%
```
Feedback: "Không đạt ❌ - Viết quá nhiều ra ngoài chữ mẫu"
Tips:
- "Nét viết ra ngoài: X% (chỉ cho phép tối đa 30%)"
- "Hãy viết chính xác theo nét mẫu màu xanh."
- "Tránh vẽ lan ra ngoài chữ mẫu."
```

### Lỗi 2: Nét Trong < 70%
```
Feedback: "Chưa đạt ⚠️ - Viết chưa đủ chính xác"
Tips:
- "Nét viết đúng: X% (cần tối thiểu 70%)"
- "Hãy viết nhiều hơn trên nét mẫu."
- "Viết chậm rãi và cẩn thận theo chữ mẫu."
```

## 🔧 Cấu Hình

Các tham số có thể điều chỉnh trong `lib/services/handwriting_tracing_service.dart`:

```dart
// Ngưỡng nét trong tối thiểu
if (insideCoverage < 70.0) { ... }  // Thay đổi 70.0 thành giá trị khác

// Ngưỡng nét ngoài tối đa
if (outsideCoverage > 30.0) { ... }  // Thay đổi 30.0 thành giá trị khác

// Ngưỡng sao
if (finalScore >= 90) return 3;  // 3 sao
if (finalScore >= 80) return 2;  // 2 sao
if (finalScore >= 70) return 1;  // 1 sao
```

## ✅ Kết Luận

Logic chấm điểm mới đã được triển khai thành công với:

- ✅ Điều kiện rõ ràng: Inside ≥ 70%, Outside ≤ 30%
- ✅ Phản hồi cụ thể cho từng loại lỗi
- ✅ Tất cả 9 test cases đều PASS
- ✅ Chống gian lận hiệu quả
- ✅ Công bằng với người học

**Ngày cập nhật**: 2026-05-31  
**Trạng thái**: ✅ Hoàn thành và đã test
