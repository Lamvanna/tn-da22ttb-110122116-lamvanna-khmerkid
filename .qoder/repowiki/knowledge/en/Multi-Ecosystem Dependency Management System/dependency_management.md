## Overview

This repository employs a **dual-ecosystem dependency management strategy** supporting both Flutter (Dart) frontend and Node.js backend components. Each ecosystem uses its native package manager with lockfile-based version pinning for reproducible builds.

---

## Frontend: Flutter/Dart Dependencies

### Package Manager: `pub`

The Flutter client uses **pub**, Dart's official package manager, configured via:

- **`pubspec.yaml`** — Declares direct dependencies with semantic versioning constraints using caret (`^`) notation (e.g., `audioplayers: ^5.2.1`, `isar: ^3.1.0+1`). This allows minor/patch updates while preventing breaking major version changes.
- **`pubspec.lock`** — Auto-generated lockfile that pins every transitive dependency to an exact version with SHA-256 integrity hashes. All packages resolve from the public registry at `https://pub.dev`.

### Key Dependency Categories

| Category | Packages |
|----------|----------|
| **Core UI** | `flutter`, `cupertino_icons`, `google_fonts`, `flutter_screenutil` |
| **Offline-First Storage** | `isar`, `isar_flutter_libs` (local NoSQL database) |
| **Networking** | `http`, `socket_io_client`, `connectivity_plus` |
| **Audio & ML** | `audioplayers`, `flutter_tts`, `record`, `google_mlkit_digital_ink_recognition` |
| **Auth & Security** | `google_sign_in`, `flutter_secure_storage` |
| **Dev Tooling** | `build_runner`, `isar_generator` (code generation), `flutter_lints` |

### Version Override Strategy

A `dependency_overrides` block in `pubspec.yaml` forces `record_linux: 1.3.0`, indicating a known compatibility issue with the default resolved version on Linux platforms. This is a targeted workaround rather than a general override pattern.

### SDK Constraint

```yaml
environment:
  sdk: ^3.11.4
```

This pins the minimum Dart SDK version, ensuring all team members and CI environments use a compatible toolchain.

---

## Backend: Node.js Dependencies

### Package Manager: `npm`

The backend uses **npm** (Node Package Manager) with:

- **`package.json`** — Declares production and dev dependencies with caret-based semver ranges. Engine constraint enforces `node >= 18.0.0`.
- **`package-lock.json`** — Lockfile (lockfileVersion 3) that captures the full dependency tree with exact versions, resolved URLs, and integrity hashes. All packages pull from the default npm registry (`https://registry.npmjs.org`).

### Key Dependency Categories

| Category | Packages |
|----------|----------|
| **Web Framework** | `express`, `cors`, `helmet`, `cookie-parser` |
| **Database** | `mongoose` (MongoDB ODM) |
| **Auth** | `jsonwebtoken`, `bcryptjs`, `passport`, `passport-google-oauth20` |
| **Real-time** | `socket.io` |
| **Cloud Services** | `cloudinary`, `multer-storage-cloudinary`, `@google-cloud/speech` |
| **Validation & Rate Limiting** | `express-validator`, `express-rate-limit` |
| **Cron Jobs** | `node-cron` |
| **Dev Tooling** | `nodemon` (auto-restart), `jest` (testing) |

### No Private Registries

All dependencies resolve from public registries. There is no evidence of private npm scopes, Verdaccio, or Artifactory configuration.

---

## Android Native Build Dependencies

### Gradle/Kotlin DSL

Android host project uses **Gradle 8.14** (defined in `gradle-wrapper.properties`) with Kotlin DSL build scripts:

- **`android/build.gradle.kts`** — Root build file configures repositories (`google()`, `mavenCentral()`) for all subprojects.
- **`android/app/build.gradle.kts`** — App-level build file applies the Flutter Gradle plugin and declares a single explicit dependency: `com.android.tools:desugar_jdk_libs:2.1.4` for Java 17 desugaring support.

Most Android dependencies are managed transitively through the Flutter plugin system rather than declared directly.

---

## Architecture & Conventions

### Separation of Concerns

- **Frontend dependencies** live at the repo root (`pubspec.yaml`, `pubspec.lock`).
- **Backend dependencies** are isolated under `backend/` (`package.json`, `package-lock.json`).
- **Native platform dependencies** (Android/iOS) are managed by their respective build systems but kept minimal, delegating to Flutter's plugin architecture.

### Reproducibility Strategy

Both ecosystems rely on **lockfiles committed to version control**:
- `pubspec.lock` ensures deterministic Dart dependency resolution.
- `package-lock.json` ensures deterministic Node.js dependency resolution.

This prevents "works on my machine" issues caused by floating semver ranges resolving to different transitive versions across environments.

### Update Workflow

- **Flutter**: Run `flutter pub upgrade --major-versions` to bump dependencies within semver constraints, then commit the updated `pubspec.lock`.
- **Node.js**: Run `npm update` to refresh dependencies within semver ranges, then commit the updated `package-lock.json`.
- Manual version bumps in manifest files require corresponding lockfile regeneration.

### No Vendoring

Neither ecosystem vendors dependencies into the repository. All third-party code is fetched from remote registries at build time.

### No Monorepo Tooling

There is no workspace configuration (e.g., npm workspaces, pnpm, Lerna, or melos). The frontend and backend are treated as independent projects with separate dependency lifecycles.

---

## Rules for Developers

1. **Never edit lockfiles manually.** Always use `flutter pub get` / `npm install` to regenerate them after modifying manifest files.
2. **Commit lockfiles.** Both `pubspec.lock` and `package-lock.json` must be tracked in Git to ensure reproducible builds across team members and CI.
3. **Use caret ranges (`^`)** for most dependencies in manifest files to allow safe minor/patch updates while blocking breaking changes.
4. **Pin SDK/runtime versions.** The Dart SDK constraint (`^3.11.4`) and Node engine constraint (`>=18.0.0`) define the minimum supported runtime. Do not lower these without verifying compatibility across all dependencies.
5. **Dependency overrides are exceptional.** The `dependency_overrides` block in `pubspec.yaml` should only be used for temporary compatibility fixes. Document the reason inline or in a related issue.
6. **Audit dependencies regularly.** Run `npm audit` for the backend and `flutter pub outdated` for the frontend to identify security vulnerabilities and available updates.
7. **Keep native dependencies minimal.** Android/iOS native dependencies should be added only when no Flutter plugin alternative exists, and must be declared in the respective platform build files.