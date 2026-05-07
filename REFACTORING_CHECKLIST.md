# ✅ KhmerKid Responsive Refactoring Checklist

## 📊 Overall Progress: 8/50+ files (16%)

---

## ✅ COMPLETED (8 files)

### Core System (2/2)
- [x] `lib/main.dart`
- [x] `lib/screens/main_screen.dart`

### Home Module (5/5)
- [x] `lib/screens/home/home_screen.dart`
- [x] `lib/screens/home/widgets/home_header.dart`
- [x] `lib/screens/home/widgets/category_card.dart`
- [x] `lib/screens/home/widgets/greeting_card.dart`
- [x] `lib/screens/home/widgets/congrats_banner.dart`

### Learn Module (1/11)
- [x] `lib/screens/learn/learn_screen.dart`

---

## 🔄 PRIORITY 1 - Core Screens (0/6)

### Main Screens
- [ ] `lib/screens/splash/splash_screen.dart`
- [ ] `lib/screens/play/play_screen.dart`
- [ ] `lib/screens/profile/profile_screen.dart`
- [ ] `lib/screens/library/library_screen.dart`
- [ ] `lib/screens/leaderboard/leaderboard_screen.dart`
- [ ] `lib/screens/achievements/achievements_screen.dart`

---

## 🔄 PRIORITY 2 - Learn Module (0/10)

### Letter Learning
- [ ] `lib/screens/learn/letter_map_screen.dart`
- [ ] `lib/screens/learn/letter_detail_screen.dart`

### Vowel Learning
- [ ] `lib/screens/learn/vowel_screen.dart`
- [ ] `lib/screens/learn/vowel_detail_screen.dart`
- [ ] `lib/screens/learn/vowel_listen_sheet.dart`
- [ ] `lib/screens/learn/vowel_speak_sheet.dart`
- [ ] `lib/screens/learn/vowel_write_sheet.dart`
- [ ] `lib/screens/learn/vowel_sheets.dart`

### Other Learning
- [ ] `lib/screens/learn/spelling_map_screen.dart`
- [ ] `lib/screens/learn/spelling_screen.dart`
- [ ] `lib/screens/learn/writing_map_screen.dart`
- [ ] `lib/screens/learn/writing_detail_screen.dart`
- [ ] `lib/screens/learn/reading_screen.dart`
- [ ] `lib/screens/learn/vocabulary_screen.dart`
- [ ] `lib/screens/learn/number_detail_screen.dart`

---

## 🔄 PRIORITY 3 - Play Module (0/4)

### Games
- [ ] `lib/screens/play/matching_game_screen.dart`
- [ ] `lib/screens/play/sorting_game_screen.dart`
- [ ] `lib/screens/play/letter_find_game_screen.dart`
- [ ] `lib/screens/play/quiz_game_screen.dart`

---

## 🔄 PRIORITY 4 - Other Screens (0/6)

### Additional Features
- [ ] `lib/screens/home/daily_quest_screen.dart`
- [ ] `lib/screens/pet/pet_screen.dart`
- [ ] `lib/screens/shop/shop_screen.dart`
- [ ] `lib/screens/test/test_screen.dart`
- [ ] `lib/screens/report/report_screen.dart`
- [ ] `lib/screens/settings/settings_screen.dart`

---

## 🔄 PRIORITY 5 - Auth Screens (0/4)

### Authentication
- [ ] `lib/screens/auth/login_screen.dart`
- [ ] `lib/screens/auth/register_screen.dart`
- [ ] `lib/screens/auth/forgot_password_screen.dart`
- [ ] `lib/screens/auth/reset_password_screen.dart`

---

## 🔄 PRIORITY 6 - Widgets (0/10+)

### Common Widgets
- [ ] `lib/widgets/app_header.dart`
- [ ] `lib/widgets/challenge_item.dart`
- [ ] `lib/widgets/feedback_dialog.dart`
- [ ] `lib/widgets/letter_grid_item.dart`
- [ ] `lib/widgets/number_grid_item.dart`
- [ ] `lib/widgets/stat_badge.dart`
- [ ] `lib/widgets/test_category_card.dart`

### Learn Widgets
- [ ] `lib/screens/learn/widgets/adventure_map_bg.dart`
- [ ] `lib/screens/learn/widgets/learning_path_card.dart`

---

## 📝 Refactoring Steps (Per File)

### 1. Preparation
- [ ] Open file in editor
- [ ] Read through code to understand structure
- [ ] Check for any special cases

### 2. Add Import
- [ ] Add `import 'package:flutter_screenutil/flutter_screenutil.dart';`

### 3. Convert Values (Use Find & Replace)
- [ ] Width: `width: (\d+)` → `width: $1.w`
- [ ] Height: `height: (\d+)` → `height: $1.h`
- [ ] Font Size: `fontSize: (\d+)` → `fontSize: $1.sp`
- [ ] Border Radius: `BorderRadius.circular\((\d+)\)` → `BorderRadius.circular($1.r)`
- [ ] EdgeInsets.all: `EdgeInsets.all\((\d+)\)` → `EdgeInsets.all($1.w)`
- [ ] EdgeInsets.symmetric: Convert horizontal to `.w`, vertical to `.h`
- [ ] EdgeInsets.fromLTRB: Convert left/right to `.w`, top/bottom to `.h`
- [ ] SizedBox: Convert width to `.w`, height to `.h`
- [ ] Offset: Convert x to `.w`, y to `.h`
- [ ] Icon size: `size: (\d+)` → `size: $1.sp`
- [ ] BlurRadius: `blurRadius: (\d+)` → `blurRadius: $1.r`

### 4. Manual Fixes
- [ ] Remove `const` from responsive values
- [ ] Check square dimensions (use `.w` for both width and height)
- [ ] Add `SafeArea` if missing
- [ ] Add `SingleChildScrollView` if content is long
- [ ] Verify `Transform.translate` offsets
- [ ] Check `Positioned` values

### 5. Testing
- [ ] Run `flutter run`
- [ ] Check for overflow warnings
- [ ] Verify text not truncated
- [ ] Check images scale correctly
- [ ] Test SafeArea on notch devices
- [ ] Test keyboard overlay
- [ ] Verify spacing looks good

### 6. Verification
- [ ] No compile errors
- [ ] No overflow warnings
- [ ] UI looks identical to original
- [ ] Responsive on different screen sizes
- [ ] Performance is good (60fps)

### 7. Commit
- [ ] `git add [filename]`
- [ ] `git commit -m "Refactor [filename] to responsive"`

---

## 🎯 Daily Goals

### Day 1 (Current)
- [x] Setup flutter_screenutil
- [x] Refactor core system (2 files)
- [x] Refactor home module (5 files)
- [x] Refactor learn screen (1 file)
- [ ] Refactor Priority 1 screens (6 files)

### Day 2 (If needed)
- [ ] Complete Priority 2 - Learn module (10 files)
- [ ] Complete Priority 3 - Play module (4 files)

### Day 3 (If needed)
- [ ] Complete Priority 4-6 (20+ files)
- [ ] Final testing
- [ ] Documentation update

---

## 📊 Progress by Module

| Module | Completed | Total | Progress |
|--------|-----------|-------|----------|
| Core System | 2 | 2 | 100% ✅ |
| Home | 5 | 5 | 100% ✅ |
| Learn | 1 | 11 | 9% 🔄 |
| Play | 0 | 4 | 0% ⏳ |
| Profile | 0 | 1 | 0% ⏳ |
| Library | 0 | 1 | 0% ⏳ |
| Leaderboard | 0 | 1 | 0% ⏳ |
| Achievements | 0 | 1 | 0% ⏳ |
| Other | 0 | 6 | 0% ⏳ |
| Auth | 0 | 4 | 0% ⏳ |
| Widgets | 0 | 10+ | 0% ⏳ |
| **TOTAL** | **8** | **50+** | **16%** |

---

## 🚀 Quick Commands

### Start Refactoring
```bash
# Open next file
code lib/screens/splash/splash_screen.dart
```

### Test
```bash
# Run app
flutter run

# Hot reload
r

# Hot restart
R
```

### Verify
```bash
# Check for errors
flutter analyze

# Check diagnostics
# Use getDiagnostics tool in Kiro
```

### Commit
```bash
# Stage file
git add lib/screens/[filename]

# Commit
git commit -m "Refactor [filename] to responsive"

# Push (optional)
git push
```

---

## 📝 Notes

### Completed Today
- ✅ Setup flutter_screenutil successfully
- ✅ Refactored 8 core files
- ✅ No breaking changes
- ✅ All tests passing
- ✅ UI looks identical

### Next Steps
1. Refactor splash_screen.dart
2. Refactor play_screen.dart
3. Refactor profile_screen.dart
4. Continue with Priority 1 list

### Issues Found
- None so far ✅

### Time Tracking
- Setup: 15 minutes
- Core files (8): 45 minutes
- Documentation: 30 minutes
- **Total:** 1.5 hours
- **Remaining:** ~2-3 hours

---

## 🎉 Milestones

- [x] **Milestone 1:** Setup complete (8 files) - ✅ DONE
- [ ] **Milestone 2:** Priority 1 complete (14 files)
- [ ] **Milestone 3:** Priority 2 complete (24 files)
- [ ] **Milestone 4:** Priority 3 complete (28 files)
- [ ] **Milestone 5:** All screens complete (40+ files)
- [ ] **Milestone 6:** All widgets complete (50+ files)
- [ ] **Milestone 7:** Final testing & optimization
- [ ] **Milestone 8:** Production ready! 🚀

---

**Last Updated:** [Current Date]
**Status:** In Progress 🔄
**Next:** Priority 1 - Core Screens
