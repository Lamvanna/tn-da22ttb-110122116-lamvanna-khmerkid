/**
 * ========================================
 * Role-Based Access Control Middleware
 * ========================================
 * 
 * Restricts route access based on user roles.
 */

const { sendError } = require('../utils/response');
const { MESSAGES } = require('../constants');

/**
 * Authorize specific roles
 * @param  {...string} roles - Allowed roles (e.g., 'admin', 'user')
 * @returns {Function} Express middleware
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return sendError(res, MESSAGES.UNAUTHORIZED, 401);
    }

    if (!roles.includes(req.user.role)) {
      return sendError(res, MESSAGES.FORBIDDEN, 403);
    }

    next();
  };
};

/**
 * Admin only middleware shorthand
 */
const adminOnly = authorize('admin');

module.exports = {
  authorize,
  adminOnly,
};
