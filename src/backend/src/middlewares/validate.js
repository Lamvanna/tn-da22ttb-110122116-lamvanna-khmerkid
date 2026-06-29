/**
 * ========================================
 * Validation Middleware Runner
 * ========================================
 * 
 * Runs express-validator validation chains
 * and returns formatted error responses.
 */

const { validationResult } = require('express-validator');
const { sendError } = require('../utils/response');
const { MESSAGES } = require('../constants');

/**
 * Run validation and handle errors
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map((err) => ({
      field: err.path,
      message: err.msg,
      value: err.value,
    }));

    return sendError(res, MESSAGES.VALIDATION_ERROR, 400, formattedErrors);
  }

  next();
};

module.exports = { validate };
