/**
 * ========================================
 * Authentication Middleware
 * ========================================
 * 
 * Verifies JWT token from Authorization header.
 * Attaches user to request object.
 */

const User = require('../models/User');
const { verifyAccessToken, extractToken } = require('../utils/token');
const { sendError } = require('../utils/response');
const { MESSAGES } = require('../constants');

/**
 * Protect routes - require authentication
 */
const authenticate = async (req, res, next) => {
  try {
    // Extract token from header or cookie
    const token = extractToken(req);

    if (!token) {
      return sendError(res, MESSAGES.UNAUTHORIZED, 401);
    }

    // Verify token
    const decoded = verifyAccessToken(token);

    // Find user and attach to request
    const user = await User.findById(decoded.id).select('-password -refreshToken');

    if (!user) {
      return sendError(res, MESSAGES.USER_NOT_FOUND, 401);
    }

    // Attach user to request
    req.user = user;
    next();

  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return sendError(res, MESSAGES.TOKEN_INVALID, 401);
    }
    if (error.name === 'TokenExpiredError') {
      return sendError(res, MESSAGES.TOKEN_EXPIRED, 401);
    }
    return sendError(res, MESSAGES.UNAUTHORIZED, 401);
  }
};

/**
 * Optional authentication - doesn't block if no token
 */
const optionalAuth = async (req, res, next) => {
  try {
    const token = extractToken(req);

    if (token) {
      const decoded = verifyAccessToken(token);
      const user = await User.findById(decoded.id).select('-password -refreshToken');
      if (user) {
        req.user = user;
      }
    }

    next();
  } catch (error) {
    // Token invalid but route is optional auth - continue
    next();
  }
};

module.exports = {
  authenticate,
  optionalAuth,
};
