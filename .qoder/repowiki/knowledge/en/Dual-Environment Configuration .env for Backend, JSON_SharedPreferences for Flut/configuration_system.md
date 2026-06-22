## Overview

The KhmerKid platform uses two distinct configuration approaches split across its backend (Node.js) and frontend (Flutter) layers:

1. **Backend**: Environment-variable-driven configuration via `dotenv`, with secrets stored in `.env` files.
2. **Frontend**: Static asset-based configuration (JSON translation/language files) combined with runtime user preferences persisted via `SharedPreferences`.

There is no unified configuration framework or feature-flag system — each layer manages its own config independently.

---

## Backend Configuration (Node.js)

### Approach
- Uses the [`dotenv`](https://www.npmjs.com/package/dotenv) package to load environment variables from a `.env` file into `process.env` at startup.
- The entry point (`backend/server.js`) calls `require('dotenv').config()` as the very first line before any other imports.
- A `.env.example` file serves as the template documenting all required variables.

### Key Files
| File | Purpose |
|------|---------|
| `backend/.env` | Actual secrets (not committed). Contains MongoDB URI, JWT secrets, OAuth credentials, Cloudinary keys, API keys. |
| `backend/.env.example` | Template with placeholder values and comments explaining each variable. |
| `backend/server.js` | Loads dotenv, reads `PORT`, `NODE_ENV`, `CLIENT_URL` from env vars. |
| `backend/src/config/database.js` | Reads `MONGO_URI` from env; configures Mongoose connection pool settings. |
| `backend/src/config/cloudinary.js` | Reads `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`. |
| `backend/src/config/passport.js` | Reads `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_CALLBACK_URL`. |
| `backend/src/constants/index.js` | Centralized application constants (roles, lesson types, game types, XP thresholds, socket event names, rate-limit messages). Not env-driven but acts as a single source of truth for business-rule configuration. |

### Environment Variables (from `.env.example`)
```bash
# Server
PORT=5000
NODE_ENV=development

# MongoDB
MONGO_URI=your_mongodb_connection_string

# JWT
JWT_SECRET=...
JWT_REFRESH_SECRET=...
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Google OAuth
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_CALLBACK_URL=http://localhost:5000/api/auth/google/callback

# Cloudinary
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...

# CORS
CLIENT_URL=http://localhost:3000

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100

# AI Services
HUGGINGFACE_API_KEY=...
GEMINI_API_KEY=...
```

### Conventions
- All sensitive config lives exclusively in `.env` (gitignored).
- Non-secret defaults are hardcoded with fallbacks in code (e.g., `process.env.PORT || 5000`, `process.env.CLIENT_URL || 'http://localhost:3000'`).
- No validation layer exists for env vars — missing values cause runtime failures silently or at first use.
- The `src/constants/index.js` module exports frozen objects for roles, lesson types, badge types, game types, difficulty levels, XP/star thresholds, upload limits, socket event names, and localized API messages. This is imported widely across controllers, services, models, and middlewares.

---

## Frontend Configuration (Flutter)

### Approach
- **No `.env` or build-time config injection**. The Flutter client does not use `flutter_dotenv` or similar packages.
- Configuration is split into three categories:
  1. **Static assets** (JSON files under `assets/translations/`) loaded at runtime via `rootBundle.loadString()`.
  2. **Hardcoded constants** in Dart files under `lib/constants/` (colors, spacing, text styles, string literals).
  3. **User preferences** persisted in `SharedPreferences` via `StorageService`.

### Key Files
| File | Purpose |
|------|---------|
| `pubspec.yaml` | Declares asset paths (`assets/translations/`, `assets/images/`, `assets/audio/khmer/*/`), dependencies, SDK constraints, and Flutter-specific config (material design, fonts). |
| `assets/translations/languages.json` | Defines supported locales (vi, km, en, zh, ja, th, ko, ar) with metadata: flag emoji, display name, native name, font family, RTL flag. Loaded dynamically by `LanguageManager`. |
| `assets/translations/{en,km,vi,ja,th,zh}.json` | Per-language translation key-value maps used by the custom i18n system. |
| `lib/l10n/language_manager.dart` | Singleton `ChangeNotifier` that loads `languages.json`, restores the user's saved locale from `StorageService`, and notifies listeners on language change. Falls back to Vietnamese (`vi`) on error. |
| `lib/services/storage_service.dart` | Wrapper around `SharedPreferences`. Stores user progress (stars, XP, streak, per-letter progress maps), settings (sound, haptics, TTS speed, offline mode, language), power-up counts with regeneration cooldowns, and cached lesson data. Keys are prefixed with `userId_` to isolate data between accounts. |
| `lib/services/auth_service.dart` | Contains **hardcoded** Google OAuth client ID (`1085311175086-0ka8le871ugi8qr0d0p5rv615qlnca3m.apps.googleusercontent.com`) and a list of candidate backend server URLs for auto-discovery (`192.168.1.4`, `172.20.10.4`, `10.0.2.2`, `localhost`). The active server URL is persisted in `SharedPreferences` under keys `saved_server_url` and `manual_server_url`. |
| `lib/constants/app_colors.dart` | Centralized color palette (primary, secondary, accent, semantic colors). |
| `lib/constants/app_text_styles.dart` | Typography scale using `GoogleFonts`. |
| `lib/constants/app_spacing.dart` | Spacing constants. |
| `lib/constants/app_strings.dart` | Hardcoded string literals (fallback when translations are unavailable). |
| `lib/main.dart` | Entry point. Initializes `LocalDatabase` (Isar), `ConnectivityService`, `LanguageManager`, `LocalNotificationService` in parallel via `Future.wait`, then `SyncManager`. Reads login state from `AuthService` to determine initial screen. |

### Server Discovery Mechanism
The Flutter app does **not** have a fixed backend URL. Instead, `AuthService.detectActiveServer()` performs a multi-tier discovery:
1. Check for a manually-set server URL in SharedPreferences (`manual_server_url`).
2. Ping the previously-saved working URL (`saved_server_url`).
3. Ping a hardcoded list of candidate IPs (home Wi-Fi, hotspot, emulator, localhost) with a 200ms timeout each.
4. If none respond, launch a background subnet scan (pinging `.1`–`.254` in batches of 32) to find the backend.

This is an unconventional configuration pattern driven by the development/deployment reality of running the backend on a local network without a fixed DNS name.

### User Preference Persistence
`StorageService` manages ~40+ preference keys covering:
- Gamification state: stars, XP, streak, per-lesson star ratings (consonants, vowels, reading, numbers, diacritical marks, spelling, writing).
- Shop/inventory: purchased items, power-up counts (hints, time, lives, double-score) with time-based regeneration logic.
- Settings: sound enabled, haptics, TTS speed (0/1/2), offline mode toggle, selected language.
- Profile: username, avatar index, avatar URL.
- Cache: downloaded lessons for offline use, test history (last 50), high scores per game.

Keys are namespaced with `userId_` prefix (derived from the logged-in user's MongoDB `_id`) to prevent data leakage between accounts on shared devices.

---

## Architecture Summary

```
┌─────────────────────────────────────────────┐
│           Backend (Node.js)                  │
│  .env → dotenv → process.env                 │
│  src/config/*.js  (DB, Cloudinary, Passport) │
│  src/constants/index.js  (business rules)    │
└─────────────────────────────────────────────┘
                    ▲
                    │ HTTP / Socket.io
                    │
┌─────────────────────────────────────────────┐
│         Frontend (Flutter)                   │
│  pubspec.yaml  (assets, deps)                │
│  assets/translations/*.json  (i18n)          │
│  lib/constants/*.dart  (UI theme)            │
│  StorageService → SharedPreferences          │
│  AuthService → hardcoded server discovery    │
└─────────────────────────────────────────────┘
```

---

## Rules Developers Should Follow

1. **Never commit `.env`**. Always update `.env.example` when adding new environment variables.
2. **Backend secrets go in `.env` only**. Do not hardcode API keys, database URIs, or OAuth credentials in source files.
3. **Use `src/constants/index.js`** for all business-rule constants (roles, types, thresholds, socket events). Do not scatter magic numbers or string literals across controllers/services.
4. **Frontend has no build-time env injection**. If you need configurable endpoints or feature flags, add them to `StorageService` or a new config service — do not introduce `flutter_dotenv` without team consensus.
5. **Server URL is dynamic**. The Flutter app discovers the backend at runtime. For production, replace the candidate IP list with a proper DNS/HTTPS endpoint.
6. **Translation keys live in `assets/translations/`**. Add new languages by creating a new JSON file and updating `languages.json`. The `LanguageManager` loads these dynamically.
7. **User preferences use `StorageService`**. Do not access `SharedPreferences` directly elsewhere in the codebase. All keys are centralized in this service.
8. **Progress keys are user-namespaced**. The `userId_` prefix in `StorageService._uKey()` ensures multi-user safety on shared devices.
