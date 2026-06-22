## Overview

The KhmerKid backend (Node.js/Express) implements a **centralized, dual-layer error handling architecture** using custom error classes, middleware pipelines, and standardized response utilities. The Flutter client uses conventional try/catch patterns with connectivity-aware retry logic.

---

## Backend: Core System

### 1. Custom `AppError` Class (`backend/src/middlewares/errorHandler.js`)

A dedicated `AppError` class extends JavaScript's native `Error` to carry operational context:

```javascript
class AppError extends Error {
  constructor(message, statusCode = 500) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true; // Distinguishes operational vs programming errors
    Error.captureStackTrace(this, this.constructor);
  }
}
```

**Key properties:**
- `statusCode`: HTTP status code (defaults to 500)
- `status`: `'fail'` for 4xx, `'error'` for 5xx
- `isOperational`: Flag indicating whether the error is expected (operational) or a bug

### 2. Global Error Handler Middleware (`globalErrorHandler`)

Registered last in the Express middleware chain (`server.js` line 121), it catches all unhandled errors:

**Error type mapping:**
| Error Type | Handler | Status Code |
|---|---|---|
| `CastError` (invalid ObjectId) | `handleCastError` | 400 |
| Duplicate key (`code === 11000`) | `handleDuplicateKeyError` | 400 |
| Mongoose `ValidationError` | `handleValidationError` | 400 |
| `JsonWebTokenError` | `handleJWTError` | 401 |
| `TokenExpiredError` | `handleJWTExpiredError` | 401 |
| Unhandled / unknown | Default | 500 |

**Response format:**
```json
{
  "success": false,
  "message": "<localized Vietnamese message>",
  "stack": "...",   // Only in development mode
  "error": { ... }  // Only in development mode
}
```

### 3. Secondary Error Handler (`backend/src/middlewares/errorHandler.middleware.js`)

A second, more specialized handler exists for domain-specific errors (speech recognition, file uploads). It introduces:

- **Request ID tracking** via `uuid` for log correlation
- **Domain-specific error codes**: `FILE_TOO_LARGE`, `STT_TIMEOUT`, `SILENCE_DETECTED`, `FILE_TOO_SMALL`, `MISSING_TARGET_WORD`, `STT_ERROR`
- **Multer error handling**: Maps upload errors to user-friendly messages

**Response format:**
```json
{
  "success": false,
  "errorCode": "STT_TIMEOUT",
  "message": "Máy chủ nhận dạng giọng nói phản hồi quá lâu. Con hãy nói lại nhé!",
  "requestId": "uuid-v4-string"
}
```

**Note:** Both handlers exist in the codebase but only `globalErrorHandler` from `errorHandler.js` is registered in `server.js`. The `errorHandler.middleware.js` appears to be an alternative or legacy version not currently wired into the main pipeline.

### 4. Response Utility (`backend/src/utils/response.js`)

Provides standardized response helpers used throughout controllers:

- `sendSuccess(res, message, data, statusCode)` — Success responses
- `sendCreated(res, message, data)` — 201 Created shorthand
- `sendError(res, message, statusCode, errors)` — Error responses with optional validation details
- `sendPaginated(res, message, data, pagination)` — Paginated list responses

All responses follow the envelope: `{ success: boolean, message: string, data?: any }`

### 5. Validation Middleware (`backend/src/middlewares/validate.js`)

Wraps `express-validator` results and returns formatted field-level errors:

```json
{
  "success": false,
  "message": "Dữ liệu không hợp lệ!",
  "errors": [
    { "field": "email", "message": "Invalid email", "value": "bad" }
  ]
}
```

---

## Error Propagation Pattern

### Controllers → Services → Middleware

Controllers uniformly use try/catch with `next(error)` delegation:

```javascript
async login(req, res, next) {
  try {
    const result = await authService.login(req.body);
    sendSuccess(res, MESSAGES.LOGIN_SUCCESS, result);
  } catch (error) {
    next(error); // Delegates to globalErrorHandler
  }
}
```

Services throw `AppError` instances for operational failures:

```javascript
if (!user) {
  throw new AppError(MESSAGES.INVALID_CREDENTIALS, 401);
}
```

### Domain-Specific Error Throwing (`speech.service.js`)

The speech service throws raw `Error` objects with sentinel string messages (`'STT_TIMEOUT'`, `'STT_ERROR'`) that are intercepted by `errorHandler.middleware.js` for translation into localized responses. This pattern bypasses `AppError` and relies on message matching.

---

## Constants & Messages (`backend/src/constants/index.js`)

All user-facing error/success messages are centralized in `MESSAGES`:

```javascript
const MESSAGES = {
  INVALID_CREDENTIALS: 'Email hoặc mật khẩu không đúng!',
  EMAIL_EXISTS: 'Email đã được sử dụng!',
  TOKEN_INVALID: 'Token không hợp lệ!',
  VALIDATION_ERROR: 'Dữ liệu không hợp lệ!',
  SERVER_ERROR: 'Lỗi server!',
  // ... etc.
};
```

Messages are in Vietnamese, reflecting the target audience.

---

## Server-Level Error Handling (`backend/server.js`)

- **404 handler**: Catches unmatched routes and creates an `AppError(404)`
- **Graceful shutdown**: Listens for `SIGTERM` and `unhandledRejection`, closes the HTTP server before exiting
- **Unhandled rejection handler**: Logs the error and exits with code 1

---

## Flutter Client Patterns

The Flutter client does not have a centralized error handling framework. Instead:

- **Try/catch blocks** are used inline in service methods (e.g., `auth_service.dart`, `sync_manager.dart`)
- **Connectivity-aware retries**: `SyncManager` implements exponential backoff for failed sync operations
- **Silent failure tolerance**: Some operations (analytics events, profile fetch after sync) catch errors without propagating them
- **Network detection**: `ConnectivityService` gates sync operations based on online/offline state

No custom exception types or error envelopes are defined on the client side.

---

## Rules for Developers

1. **Always throw `AppError`** in services for expected/operational errors. Never throw raw `Error` unless integrating with the speech-service sentinel pattern.
2. **Use `next(error)`** in controllers — never handle errors locally with `res.status().json()`.
3. **Define messages in `MESSAGES`** constant — do not hardcode error strings in services.
4. **Use `sendSuccess`/`sendError`** utilities for consistent response formatting.
5. **Set `isOperational = true`** only for errors you expect (validation, auth failures). Programming errors (null references, type errors) should crash and be caught by `unhandledRejection`.
6. **Log in development only**: Stack traces and full error objects are suppressed in production responses.
7. **For new domain-specific errors**: Either extend `AppError` with an `errorCode` field or add a new case to the secondary error handler's message-matching logic.
