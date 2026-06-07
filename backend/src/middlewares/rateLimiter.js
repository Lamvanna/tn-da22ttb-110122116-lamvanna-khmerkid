/**
 * ========================================
 * Rate Limiter Configuration
 * ========================================
 * 
 * Different rate limits for different
 * endpoint groups.
 */

const rateLimit = require('express-rate-limit');
const { MESSAGES } = require('../constants');

const isDev = process.env.NODE_ENV === 'development' || true; // Force dev friendly limits for local runs

/**
 * General API rate limiter
 * 100 requests per 15 minutes (relaxed in development)
 */
const generalLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: isDev ? 100000 : (parseInt(process.env.RATE_LIMIT_MAX) || 100),
  message: {
    success: false,
    message: MESSAGES.RATE_LIMIT,
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Auth rate limiter - stricter
 * 20 requests per 15 minutes (relaxed in development)
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: isDev ? 100000 : 20,
  message: {
    success: false,
    message: 'Quá nhiều lần đăng nhập. Vui lòng thử lại sau 15 phút.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Upload rate limiter
 * 30 uploads per 15 minutes
 */
const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  message: {
    success: false,
    message: 'Quá nhiều lượt upload. Vui lòng thử lại sau.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  generalLimiter,
  authLimiter,
  uploadLimiter,
};
