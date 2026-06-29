/**
 * ========================================
 * Auth Validators
 * ========================================
 */

const { body } = require('express-validator');

const registerValidator = [
  body('name')
    .trim()
    .notEmpty().withMessage('Tên là bắt buộc')
    .isLength({ min: 2, max: 50 }).withMessage('Tên từ 2-50 ký tự'),
  body('email')
    .trim()
    .notEmpty().withMessage('Email là bắt buộc')
    .isEmail().withMessage('Email không hợp lệ')
    .normalizeEmail(),
  body('password')
    .notEmpty().withMessage('Mật khẩu là bắt buộc')
    .isLength({ min: 6 }).withMessage('Mật khẩu tối thiểu 6 ký tự'),
];

const loginValidator = [
  body('email')
    .trim()
    .notEmpty().withMessage('Email là bắt buộc')
    .isEmail().withMessage('Email không hợp lệ')
    .normalizeEmail(),
  body('password')
    .notEmpty().withMessage('Mật khẩu là bắt buộc'),
];

const refreshTokenValidator = [
  body('refreshToken')
    .notEmpty().withMessage('Refresh token là bắt buộc'),
];

module.exports = {
  registerValidator,
  loginValidator,
  refreshTokenValidator,
};
