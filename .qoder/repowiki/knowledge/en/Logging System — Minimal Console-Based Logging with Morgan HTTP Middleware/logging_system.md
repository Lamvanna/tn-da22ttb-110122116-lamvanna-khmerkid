## Overview

The KhmerKid repository uses a **minimal, ad-hoc logging approach** without any dedicated logging framework (e.g., Winston, Pino, Bunyan) or structured logging library. Logging is handled through built-in console methods and Flutter's `debugPrint`, with environment-aware formatting for HTTP request logging via Morgan.

---

## Backend (Node.js/Express)

### HTTP Request Logging — Morgan

- **Framework**: [`morgan`](https://www.npmjs.com/package/morgan) (^1.10.0) is the only formal logging dependency.
- **Configuration** (`backend/server.js`):
  - **Development**: Uses `morgan('dev')` — concise colored output showing method, URL, status, response length, and response time.
  - **Production**: Uses `morgan('combined')` — Apache combined log format including remote address, user, date, method, URL, HTTP version, status, referrer, and user-agent.
- **Routing**: Applied as Express middleware before body parsers, affecting all incoming HTTP requests.

### Application-Level Logging — Bare `console` Calls

- No custom logger utility exists. All application-level logging uses raw `console.log`, `console.error`, and `console.warn`.
- **Key locations**:
  - `backend/src/config/database.js`: MongoDB connection events (connected, error, disconnected) logged with emoji-prefixed messages (✅, ❌, 🔄, 💀).
  - `backend/server.js`: Server startup banner (ASCII-art style), SIGTERM shutdown messages, unhandled rejection errors.
  - `backend/src/middlewares/errorHandler.js`: Error details logged to `console.error` only when `NODE_ENV === 'development'`, including message, stack trace, and status code.
- **No log levels**: There is no centralized log-level management. Developers manually decide whether to log based on `process.env.NODE_ENV` checks (only in the error handler).
- **No structured fields**: Log output is free-form text strings. No JSON serialization, no correlation IDs, no request tracing.

### Scratch/Debug Scripts

- Files under `backend/scratch/` and root-level debug scripts (e.g., `fix_admin_token.js`) use `console.log`/`console.error` for one-off diagnostics. These are not part of the production logging strategy.

---

## Frontend (Flutter/Dart)

### Debug Printing — `debugPrint`

- **No logging package**: The `pubspec.yaml` does not include any logging dependency (e.g., `logger`, `logging`).
- **Primary mechanism**: `debugPrint()` from `package:flutter/foundation.dart` is used throughout the codebase for diagnostic output.
- **Conditional printing**: Many files wrap `print()` calls inside `if (kDebugMode)` guards (from `package:flutter/foundation.dart`), ensuring logs are stripped in release builds.
- **Tagged prefixes**: Logs commonly use bracketed module tags for identification, e.g., `[LocalDB]`, `[LessonLocalDS]`, `[SyncQueue]`, `[LessonRemoteDS]`.
- **Error handling**: Caught exceptions are logged via `debugPrint` with warning emoji prefixes (⚠️), e.g., in `lib/main.dart` for auto-login failures and notification scheduling errors.

### No Production Logging Sink

- There is no file-based logging, remote log aggregation, or crash reporting service integrated into the Flutter app.
- Logs are ephemeral — visible only during development via IDE console or `flutter run` output.

---

## Architecture & Conventions

| Aspect | Backend | Frontend |
|---|---|---|
| Framework | Morgan (HTTP only) | None |
| App logging | `console.log` / `console.error` | `debugPrint` / `print` |
| Log levels | None (manual env checks) | None (kDebugMode guard) |
| Structured output | No | No |
| File rotation | No | No |
| Remote aggregation | No | No |
| Error context | Stack traces in dev only | Exception message only |

### Design Decisions (Inferred)

1. **Simplicity over sophistication**: The project prioritizes minimal dependencies and straightforward debugging over enterprise-grade observability.
2. **Environment-aware verbosity**: Backend error details are suppressed in production; frontend debug prints are guarded by `kDebugMode`.
3. **Emoji-enhanced readability**: Console messages use emojis (✅, ❌, ⚠️, 🔄, 💀, 📡) for visual scanning in terminal output.
4. **Module-tagged prefixes**: Dart code uses consistent `[ModuleName]` prefixes to aid log filtering during development.

---

## Rules for Developers

1. **Backend logging**:
   - Use `console.log` for informational messages and `console.error` for errors.
   - Wrap sensitive or verbose error details behind `process.env.NODE_ENV === 'development'` checks.
   - Do not introduce new logging frameworks unless there is a team-wide decision to adopt one.
   - Morgan handles HTTP request logging automatically — do not add manual request/response logging in controllers.

2. **Frontend logging**:
   - Prefer `debugPrint` over `print` for multi-line or verbose output (Flutter throttles `debugPrint` to avoid dropping logs).
   - Guard `print` calls with `if (kDebugMode)` to prevent leakage in release builds.
   - Use bracketed module tags (e.g., `[AuthService]`, `[SyncManager]`) for easy grep/filtering.
   - Do not commit temporary `print` statements used for debugging — clean them up before merging.

3. **General**:
   - Avoid logging sensitive data (tokens, passwords, PII) at any level.
   - Keep log messages concise and actionable.
   - If adding error logging, include enough context (operation name, relevant IDs) to aid troubleshooting.
