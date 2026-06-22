## Overview

The KhmerKid project uses a **dual-stack build system** with no centralized orchestration. The Flutter mobile client and Node.js backend are built, tested, and deployed independently using their respective ecosystem toolchains.

---

## Frontend (Flutter Mobile App)

### Build Toolchain
- **Primary tool**: Flutter CLI (`flutter build`, `flutter run`)
- **Dependency management**: `pubspec.yaml` with locked versions in `pubspec.lock`
- **Code generation**: `build_runner` for Isar database code generation (`isar_generator`)
- **Static analysis**: `flutter analyze` configured via `analysis_options.yaml` extending `flutter_lints`

### Android Build Configuration
- **Build system**: Gradle with Kotlin DSL (`.kts` files)
- **Key files**:
  - `android/build.gradle.kts` — root project config; sets `compileSdkVersion(36)` globally for subprojects, redirects build output to a shared `../../build` directory
  - `android/app/build.gradle.kts` — app module config; applies `dev.flutter.flutter-gradle-plugin`, sets namespace `com.khmerkid.khmerkid`, Java 17 compatibility, core library desugaring enabled
  - `android/gradle.properties` — JVM args tuned for large heaps (`-Xmx8G`), AndroidX enabled
- **Signing**: Release builds currently use debug signing config (TODO noted in source)

### iOS Build Configuration
- **Build system**: Xcode via Flutter's generated xcconfig files
- **Key files**:
  - `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig` — Flutter-generated build configurations
  - `ios/Runner.xcodeproj/project.pbxproj` — Xcode project definition
- No custom iOS build overrides detected; relies on Flutter defaults

### Versioning
- Defined in `pubspec.yaml`: `version: 1.0.0+1` (semantic version + build number)
- Android `versionCode`/`versionName` pulled from Flutter's version via `flutter.versionCode` / `flutter.versionName`

### Utility Scripts
- `check_size.bat` — Windows batch script using PowerShell to report sizes of `build/`, `.dart_tool/`, and `android/.gradle/`; recommends `flutter clean` when total exceeds 2000 MB

---

## Backend (Node.js API Server)

### Build Toolchain
- **Runtime**: Node.js >= 18.0.0 (enforced via `engines` field)
- **Dependency management**: npm with `package-lock.json`
- **No compilation step**: JavaScript source runs directly via `node server.js`

### NPM Scripts (defined in `backend/package.json`)
| Script | Purpose |
|--------|---------|
| `npm run dev` | Development with hot-reload via `nodemon` |
| `npm start` | Production entry point (`node server.js`) |
| `npm run seed` | Full database seeding (`seedAll.js`) |
| `npm run seed:badges` | Seed badges only |
| `npm run seed:missions` | Seed missions only |
| `npm run seed:lessons` | Seed lessons only |
| `npm test` | Run Jest test suite |

### Environment Configuration
- `.env` file for runtime secrets (MongoDB URI, JWT keys, OAuth credentials, Cloudinary, HuggingFace, Gemini API keys)
- `.env.example` provided as template with placeholder values
- Loaded via `dotenv` package

### Testing
- Framework: Jest
- Test files located in `backend/test/` covering services (TTS, stroke analyzers, scoring, reward calculator) and utilities (Khmer normalizer)

---

## What Is Missing

- **No CI/CD pipelines**: No `.github/workflows/`, GitLab CI, CircleCI, or Jenkins configuration found
- **No containerization**: No `Dockerfile` or `docker-compose.yml`
- **No Makefile or task runner**: No unified build orchestration across frontend and backend
- **No release automation**: Version bumping, changelog generation, and artifact publishing are manual
- **No deployment scripts**: No infrastructure-as-code or deploy hooks

---

## Developer Conventions

1. **Frontend development**: Use `flutter pub get` after dependency changes; run `flutter pub run build_runner build` after modifying Isar models
2. **Backend development**: Use `npm run dev` for local development; ensure `.env` is populated from `.env.example`
3. **Database seeding**: Run `npm run seed` in `backend/` before first launch to populate initial data
4. **Cleanup**: Run `flutter clean` periodically to manage disk usage (monitored via `check_size.bat`)
5. **Testing**: Run `npm test` in `backend/` for backend unit tests; `flutter test` for widget tests in root
