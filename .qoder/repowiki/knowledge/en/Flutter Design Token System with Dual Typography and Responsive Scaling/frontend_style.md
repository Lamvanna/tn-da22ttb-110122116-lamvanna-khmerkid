## Overview

KhmerKid uses a **Flutter Material 3** design system built around a centralized **design token architecture**. The styling approach combines semantic color tokens, a structured spacing scale, responsive scaling via `flutter_screenutil`, and a dual-font typography system optimized for both Latin/Vietnamese and Khmer script legibility.

---

## Core Architecture

### Design Tokens (`lib/theme/design_tokens.dart`)

The primary source of truth is the `design_tokens.dart` file, which defines:

- **Semantic Colors (`KkColors`)**: Role-based color tokens (e.g., `brand`, `surfaceBase`, `moduleLearn`, `stepListen`) rather than raw hex values. Widgets are required to use these tokens instead of hardcoding `Color(0xFF...)`.
- **Spacing Scale (`Spacing`)**: An 8-point grid system using `flutter_screenutil` extensions (`.w`, `.h`). Tokens range from `s1` (4dp) to `s12` (48dp), with `s4` (16dp) as the default.
- **Radius Scale (`Radii`)**: Predefined border radii from `xs` (6dp) to `full` (pill/circle).
- **Elevation Tiers (`Elevation`)**: Three shadow tiers (`e1`, `e2`, `e3`) using two-layer shadows for depth, plus a brand-tinted shadow variant.
- **Motion Constants (`Motion`)**: Named durations (`micro`, `fast`, `normal`, etc.) and curves (`enter`, `exit`, `bouncy`) for consistent animation timing.
- **Responsive Breakpoints (`Breakpoint`)**: Mobile (≤600px), tablet (601–1024px), desktop (>1024px) with an extension on `BuildContext` for grid columns and screen padding.

### Legacy Color System (`lib/constants/app_colors.dart`)

A parallel `AppColors` class exists with hardcoded color constants organized by module (primary blue, green, gold, violet, coral). This file contains legacy aliases and gradient definitions. There is evidence of a migration toward the newer `KkColors` token system, but both coexist in the codebase.

### Typography System

Two typography systems operate in parallel:

1. **`KkType` (`lib/theme/app_typography.dart`)**: The modern type scale using Major Third (1.25) ratio. It enforces:
   - Only 4 font weights (400, 500, 600, 700)
   - Explicit `height` (line-height) on every style to prevent Khmer diacritic clipping
   - Dual fonts: **Plus Jakarta Sans** for Latin/Vietnamese, **Battambang** for Khmer (scaled 20% larger for legibility)
   - Tabular figures for numeric stats
   - Convenience extensions like `.onBrand`, `.secondary` for color application

2. **`AppTextStyles` (`lib/constants/app_text_styles.dart`)**: A legacy static TextStyle collection using `GoogleFonts.plusJakartaSans` and `GoogleFonts.battambang` without enforced line heights or responsive sizing.

### Theme Configuration (`lib/theme/app_theme.dart`)

The `AppTheme.lightTheme` configures Material 3 with:
- `useMaterial3: true`
- Custom `ColorScheme.light` mapped to `AppColors` constants
- `GoogleFonts.plusJakartaSansTextTheme()` as the base text theme
- Styled `AppBarTheme`, `CardThemeData` (20dp rounded corners, no shadow), `ElevButtonTheme` (stadium border), and `BottomNavigationBarTheme`

---

## Responsive Strategy

The app uses **`flutter_screenutil`** for responsive scaling:

- Initialized in `main.dart` with `designSize: Size(393, 852)` (iPhone 14 reference)
- All spacing, radius, and font sizes use `.w`, `.h`, `.sp`, `.r` extensions
- `minTextAdapt: true` and `splitScreenMode: true` for foldable/tablet support
- Breakpoint-aware layout helpers via `KkResponsive` extension on `BuildContext`

---

## Key Conventions and Rules

1. **No Hardcoded Colors**: New widgets must use `KkColors` semantic tokens, not raw `Color(0xFF...)` values.
2. **Khmer Text Requires Line Height**: Every `TextStyle` for Khmer content must specify `height` to avoid diacritic clipping.
3. **Minimum Touch Target**: 48dp minimum for all interactive elements (`TapTarget.min`).
4. **Font Weight Restriction**: Only weights 400, 500, 600, 700 are permitted to reduce bundle size and maintain visual consistency.
5. **Spacing via Tokens**: Use `Spacing.s4` instead of `EdgeInsets.all(16.w)` for consistency.
6. **Dual Font Strategy**: Plus Jakarta Sans for UI/Latin text; Battambang for Khmer characters, scaled proportionally larger.
7. **WCAG AA Compliance**: Text colors are chosen to meet WCAG AA contrast ratios (e.g., `textTertiary` at 4.6:1 on white).

---

## Migration State

The codebase shows signs of an ongoing migration from the legacy `AppColors`/`AppTextStyles`/`AppSpacing` system to the newer `KkColors`/`KkType`/`Spacing`/`Radii`/`Elevation`/`Motion` token architecture. Some screens (e.g., `home_screen.dart`) already use the new tokens, while others still reference the old constants.