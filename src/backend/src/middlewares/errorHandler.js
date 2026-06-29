/**
 * ========================================
 * Global Error Handler
 * ========================================
 * 
 * Custom AppError class and centralized
 * error handling middleware.
 */

/**
 * Custom Application Error class
 */
class AppError extends Error {
  constructor(message, statusCode = 500) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Handle Mongoose CastError (invalid ObjectId)
 */
const handleCastError = (err) => {
  return new AppError(`Invalid ${err.path}: ${err.value}`, 400);
};

/**
 * Handle Mongoose duplicate key error
 */
const handleDuplicateKeyError = (err) => {
  const field = Object.keys(err.keyValue)[0];
  return new AppError(`${field} đã tồn tại. Vui lòng sử dụng giá trị khác.`, 400);
};

/**
 * Handle Mongoose validation error
 */
const handleValidationError = (err) => {
  const messages = Object.values(err.errors).map((e) => e.message);
  return new AppError(`Dữ liệu không hợp lệ: ${messages.join('. ')}`, 400);
};

/**
 * Handle JWT errors
 */
const handleJWTError = () => {
  return new AppError('Token không hợp lệ. Vui lòng đăng nhập lại.', 401);
};

const handleJWTExpiredError = () => {
  return new AppError('Token đã hết hạn. Vui lòng đăng nhập lại.', 401);
};

/**
 * Global error handler middleware
 */
const globalErrorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  // Log error in development
  if (process.env.NODE_ENV === 'development') {
    console.error('❌ Error:', {
      message: err.message,
      stack: err.stack,
      statusCode: err.statusCode,
    });
  }

  // Handle specific error types
  let error = { ...err, message: err.message };

  if (err.name === 'CastError') error = handleCastError(err);
  if (err.code === 11000) error = handleDuplicateKeyError(err);
  if (err.name === 'ValidationError') error = handleValidationError(err);
  if (err.name === 'JsonWebTokenError') error = handleJWTError();
  if (err.name === 'TokenExpiredError') error = handleJWTExpiredError();

  // Send response
  res.status(error.statusCode || 500).json({
    success: false,
    message: error.message || 'Lỗi server!',
    ...(process.env.NODE_ENV === 'development' && {
      stack: err.stack,
      error: err,
    }),
  });
};

module.exports = {
  AppError,
  globalErrorHandler,
};
