# 🚀 Quick Refactor Template

## Copy-Paste Template cho Refactoring Nhanh

### 1. Import Statement (Thêm vào đầu file)
```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
```

### 2. Find & Replace Patterns

#### A. Width Values
```
Find:    width: (\d+)
Replace: width: $1.w
```

#### B. Height Values
```
Find:    height: (\d+)
Replace: height: $1.h
```

#### C. Font Size
```
Find:    fontSize: (\d+)
Replace: fontSize: $1.sp
```

#### D. Border Radius
```
Find:    BorderRadius\.circular\((\d+)\)
Replace: BorderRadius.circular($1.r)
```

#### E. EdgeInsets.all
```
Find:    EdgeInsets\.all\((\d+)\)
Replace: EdgeInsets.all($1.w)
```

#### F. EdgeInsets.symmetric
```
Find:    EdgeInsets\.symmetric\(horizontal: (\d+), vertical: (\d+)\)
Replace: EdgeInsets.symmetric(horizontal: $1.w, vertical: $2.h)
```

#### G. EdgeInsets.fromLTRB
```
Find:    EdgeInsets\.fromLTRB\((\d+), (\d+), (\d+), (\d+)\)
Replace: EdgeInsets.fromLTRB($1.w, $2.h, $3.w, $4.h)
```

#### H. SizedBox
```
Find:    SizedBox\(width: (\d+)\)
Replace: SizedBox(width: $1.w)

Find:    SizedBox\(height: (\d+)\)
Replace: SizedBox(height: $1.h)

Find:    SizedBox\(width: (\d+), height: (\d+)\)
Replace: SizedBox(width: $1.w, height: $2.h)
```

#### I. Offset
```
Find:    Offset\((\d+), (\d+)\)
Replace: Offset($1.w, $2.h)
```

#### J. Icon Size
```
Find:    size: (\d+)\)
Replace: size: $1.sp)
```

#### K. BlurRadius
```
Find:    blurRadius: (\d+)
Replace: blurRadius: $1.r
```

### 3. Manual Replacements (Cần check context)

#### const EdgeInsets → EdgeInsets
```dart
// ❌ TRƯỚC
const EdgeInsets.all(16)

// ✅ SAU (remove const)
EdgeInsets.all(16.w)
```

#### const SizedBox → SizedBox
```dart
// ❌ TRƯỚC
const SizedBox(width: 12)

// ✅ SAU (remove const)
SizedBox(width: 12.w)
```

#### const Offset → Offset
```dart
// ❌ TRƯỚC
const Offset(0, 4)

// ✅ SAU (remove const)
Offset(0, 4.h)
```

### 4. Special Cases

#### A. Square Dimensions (Avatar, Icon Container)
```dart
// Use .w for both width and height
Container(
  width: 56.w,
  height: 56.w,  // ← .w not .h
  decoration: BoxDecoration(shape: BoxShape.circle),
)
```

#### B. Transform.translate
```dart
// ❌ TRƯỚC
Transform.translate(
  offset: const Offset(0, -28),
  child: Widget(),
)

// ✅ SAU
Transform.translate(
  offset: Offset(0, -28.h),
  child: Widget(),
)
```

#### C. Positioned
```dart
// ❌ TRƯỚC
Positioned(
  left: 20, top: 45, right: 30, bottom: 10,
  child: Widget(),
)

// ✅ SAU
Positioned(
  left: 20.w, top: 45.h, right: 30.w, bottom: 10.h,
  child: Widget(),
)
```

#### D. LinearProgressIndicator
```dart
// ❌ TRƯỚC
LinearProgressIndicator(
  minHeight: 6,
  strokeWidth: 5,
)

// ✅ SAU
LinearProgressIndicator(
  minHeight: 6.h,
  strokeWidth: 5.w,
)
```

#### E. CircularProgressIndicator
```dart
// ❌ TRƯỚC
CircularProgressIndicator(
  strokeWidth: 5,
)

// ✅ SAU
CircularProgressIndicator(
  strokeWidth: 5.w,
)
```

### 5. SafeArea Wrapper

#### Add SafeArea if missing
```dart
// ❌ TRƯỚC
Scaffold(
  body: Column(...),
)

// ✅ SAU
Scaffold(
  body: SafeArea(
    child: Column(...),
  ),
)
```

#### BottomNavigationBar
```dart
// ✅ Always wrap with SafeArea
bottomNavigationBar: SafeArea(
  child: BottomNavigationBar(...),
)
```

### 6. ScrollView for Long Content

```dart
// ✅ Add SingleChildScrollView if content might overflow
Scaffold(
  body: SafeArea(
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(...),
    ),
  ),
)
```

## 🎯 Refactoring Workflow

### Step 1: Backup (Optional)
```bash
git add .
git commit -m "Before refactoring [filename]"
```

### Step 2: Add Import
```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
```

### Step 3: Auto Replace (VS Code)
1. Press `Ctrl+H` (Windows) or `Cmd+H` (Mac)
2. Enable Regex mode (icon: `.*`)
3. Use Find & Replace patterns above
4. Replace All or Replace one by one

### Step 4: Manual Check
- [ ] Remove `const` from responsive values
- [ ] Check square dimensions (use `.w` for both)
- [ ] Verify SafeArea placement
- [ ] Check ScrollView if needed

### Step 5: Test
```bash
flutter run
```

### Step 6: Verify
- [ ] No overflow warnings
- [ ] Text not truncated
- [ ] Images scale correctly
- [ ] Spacing looks good
- [ ] SafeArea works

### Step 7: Commit
```bash
git add .
git commit -m "Refactor [filename] to responsive"
```

## 📝 Example: Complete Refactoring

### BEFORE
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: 200,
            height: 100,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Hello',
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
          Icon(Icons.star, size: 24),
        ],
      ),
    );
  }
}
```

### AFTER
```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: 200.w,
              height: 100.h,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Hello',
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
            SizedBox(height: 20.h),
            Icon(Icons.star, size: 24.sp),
          ],
        ),
      ),
    );
  }
}
```

## ⚠️ Common Mistakes

### ❌ DON'T
```dart
// Don't use .h for square dimensions
Container(width: 50.w, height: 50.h) // ← Wrong for circles

// Don't keep const with responsive values
const EdgeInsets.all(16.w) // ← Error

// Don't forget import
// Missing: import 'package:flutter_screenutil/flutter_screenutil.dart';
```

### ✅ DO
```dart
// Use .w for square dimensions
Container(width: 50.w, height: 50.w) // ← Correct for circles

// Remove const
EdgeInsets.all(16.w) // ← Correct

// Always add import
import 'package:flutter_screenutil/flutter_screenutil.dart';
```

## 🎯 Priority Order

1. **Import** - Add flutter_screenutil import
2. **Dimensions** - width, height
3. **Text** - fontSize
4. **Spacing** - padding, margin, SizedBox
5. **Radius** - borderRadius
6. **Icons** - icon size
7. **Shadows** - blurRadius, offset
8. **SafeArea** - Add if missing
9. **ScrollView** - Add if content is long
10. **Test** - Run and verify

---

**Tip:** Sử dụng VS Code Multi-cursor (Alt+Click) để refactor nhiều dòng cùng lúc!
