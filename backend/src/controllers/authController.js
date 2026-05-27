/**
 * ========================================
 * Auth Controller
 * ========================================
 */

const authService = require('../services/authService');
const { sendSuccess, sendCreated } = require('../utils/response');
const { MESSAGES } = require('../constants');
const passport = require('passport');
const { generateTokenPair } = require('../utils/token');

class AuthController {
  /** POST /api/auth/register */
  async register(req, res, next) {
    try {
      const result = await authService.register(req.body);
      sendCreated(res, MESSAGES.REGISTER_SUCCESS, result);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/auth/login */
  async login(req, res, next) {
    try {
      const result = await authService.login(req.body);
      sendSuccess(res, MESSAGES.LOGIN_SUCCESS, result);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/auth/logout */
  async logout(req, res, next) {
    try {
      await authService.logout(req.user._id);
      sendSuccess(res, MESSAGES.LOGOUT_SUCCESS);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/auth/refresh-token */
  async refreshToken(req, res, next) {
    try {
      const { refreshToken } = req.body;
      const tokens = await authService.refreshToken(refreshToken);
      sendSuccess(res, MESSAGES.TOKEN_REFRESHED, tokens);
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/auth/google */
  googleLogin(req, res, next) {
    passport.authenticate('google', {
      scope: ['profile', 'email'],
    })(req, res, next);
  }

  /** GET /api/auth/google/callback */
  googleCallback(req, res, next) {
    passport.authenticate('google', { session: false }, async (err, user) => {
      try {
        if (err || !user) {
          return res.redirect(`${process.env.CLIENT_URL}/login?error=google_auth_failed`);
        }

        const result = await authService.googleLogin(user);

        // Redirect with tokens (for mobile deep link or web)
        const redirectUrl = `${process.env.CLIENT_URL}/auth/callback?accessToken=${result.accessToken}&refreshToken=${result.refreshToken}`;
        res.redirect(redirectUrl);
      } catch (error) {
        next(error);
      }
    })(req, res, next);
  }

  /** POST /api/auth/google/mobile-signin */
  async mobileGoogleLogin(req, res, next) {
    try {
      const { idToken } = req.body;
      const result = await authService.mobileGoogleLogin(idToken);
      sendSuccess(res, MESSAGES.LOGIN_SUCCESS, result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();
