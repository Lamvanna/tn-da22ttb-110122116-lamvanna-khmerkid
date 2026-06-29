/**
 * ========================================
 * Standardized API Response Helper
 * ========================================
 * 
 * All API responses follow the format:
 * { success: boolean, message: string, data: any }
 */

/**
 * Send success response
 * @param {Object} res - Express response object
 * @param {string} message - Success message
 * @param {*} data - Response data
 * @param {number} statusCode - HTTP status code
 */
const sendSuccess = (res, message = 'Success', data = null, statusCode = 200) => {
  const response = {
    success: true,
    message,
  };

  if (data !== null && data !== undefined) {
    response.data = data;
  }

  return res.status(statusCode).json(response);
};

/**
 * Send created response (201)
 * @param {Object} res - Express response object
 * @param {string} message - Success message
 * @param {*} data - Response data
 */
const sendCreated = (res, message = 'Created', data = null) => {
  return sendSuccess(res, message, data, 201);
};

/**
 * Send error response
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @param {number} statusCode - HTTP status code
 * @param {*} errors - Validation errors or details
 */
const sendError = (res, message = 'Error', statusCode = 500, errors = null) => {
  const response = {
    success: false,
    message,
  };

  if (errors) {
    response.errors = errors;
  }

  return res.status(statusCode).json(response);
};

/**
 * Send paginated response
 * @param {Object} res - Express response object
 * @param {string} message - Success message
 * @param {*} data - Response data
 * @param {Object} pagination - Pagination info
 */
const sendPaginated = (res, message = 'Success', data = [], pagination = {}) => {
  return res.status(200).json({
    success: true,
    message,
    data,
    pagination,
  });
};

module.exports = {
  sendSuccess,
  sendCreated,
  sendError,
  sendPaginated,
};
