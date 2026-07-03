/**
 * ========================================
 * Auth Routes
 * ========================================
 * 
 * POST /api/auth/register
 * POST /api/auth/login
 * POST /api/auth/logout
 * POST /api/auth/refresh-token
 * GET  /api/auth/google
 * GET  /api/auth/google/callback
 */

const router = require('express').Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middlewares/auth');
const { validate } = require('../middlewares/validate');
const { authLimiter } = require('../middlewares/rateLimiter');
const { registerValidator, loginValidator, refreshTokenValidator } = require('../validators/authValidator');

// Rate limit auth routes
router.use(authLimiter);

// Public routes
router.post('/register', registerValidator, validate, authController.register);
router.post('/login', loginValidator, validate, authController.login);
router.post('/refresh-token', refreshTokenValidator, validate, authController.refreshToken);

// Google OAuth
router.get('/google', authController.googleLogin);
router.get('/google/callback', authController.googleCallback);
router.post('/google/mobile-signin', authController.mobileGoogleLogin);
// Password Recovery
router.post('/forgot-password', authController.forgotPassword);
router.post('/verify-otp', authController.verifyOTP);
router.post('/reset-password', authController.resetPassword);

// Protected routes
router.post('/logout', authenticate, authController.logout);

module.exports = router;
