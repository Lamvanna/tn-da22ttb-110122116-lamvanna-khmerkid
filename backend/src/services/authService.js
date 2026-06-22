/**
 * ========================================
 * Auth Service
 * ========================================
 * 
 * Business logic for authentication:
 * register, login, logout, refresh token.
 */

const User = require('../models/User');
const { generateTokenPair, verifyRefreshToken } = require('../utils/token');
const { calculateStreak } = require('../utils/helpers');
const { AppError } = require('../middlewares/errorHandler');
const { MESSAGES, AUTH_PROVIDERS, XP_CONFIG } = require('../constants');
const missionService = require('./missionService');

class AuthService {
  /**
   * Register a new user
   */
  async register({ name, email, password }) {
    // Check if email already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      throw new AppError(MESSAGES.EMAIL_EXISTS, 400);
    }

    // Create user
    const user = await User.create({
      name,
      email,
      password,
      authProvider: AUTH_PROVIDERS.LOCAL,
    });

    // Generate tokens
    const tokens = generateTokenPair(user);

    // Save refresh token
    user.refreshToken = tokens.refreshToken;
    await user.save();

    return {
      user: user.toJSON(),
      ...tokens,
    };
  }

  /**
   * Login with email and password
   */
  async login({ email, password }) {
    // Find user with password field
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      throw new AppError(MESSAGES.INVALID_CREDENTIALS, 401);
    }

    // Check if user registered with Google
    if (user.authProvider === AUTH_PROVIDERS.GOOGLE && !user.password) {
      throw new AppError('Tài khoản này sử dụng đăng nhập Google. Vui lòng đăng nhập bằng Google.', 400);
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      throw new AppError(MESSAGES.INVALID_CREDENTIALS, 401);
    }

    // Update streak
    const { streak, isNewDay } = calculateStreak(user.lastLoginDate, new Date(), user.streak);
    user.streak = streak;
    if (streak > user.longestStreak) {
      user.longestStreak = streak;
    }

    // Award daily login XP
    if (isNewDay) {
      user.xp += XP_CONFIG.DAILY_LOGIN + (XP_CONFIG.STREAK_BONUS * streak);
      // Update daily login mission
      try {
        await missionService.updateProgress(user._id, 'daily_login');
      } catch (missionErr) {
        console.error('Error updating daily_login mission:', missionErr.message);
      }
    }

    user.lastLoginDate = new Date();
    user.lastActiveDate = new Date();

    // Generate tokens
    const tokens = generateTokenPair(user);
    user.refreshToken = tokens.refreshToken;

    await user.save();

    return {
      user: user.toJSON(),
      ...tokens,
    };
  }

  /**
   * Logout - clear refresh token
   */
  async logout(userId) {
    await User.findByIdAndUpdate(userId, {
      refreshToken: null,
    });
  }

  /**
   * Refresh access token
   */
  async refreshToken(refreshToken) {
    if (!refreshToken) {
      throw new AppError('Refresh token là bắt buộc', 400);
    }

    // Verify refresh token
    const decoded = verifyRefreshToken(refreshToken);

    // Find user with matching refresh token
    const user = await User.findById(decoded.id).select('+refreshToken');

    if (!user || user.refreshToken !== refreshToken) {
      throw new AppError(MESSAGES.TOKEN_INVALID, 401);
    }

    // Generate new tokens
    const tokens = generateTokenPair(user);

    // Update refresh token
    user.refreshToken = tokens.refreshToken;
    await user.save();

    return tokens;
  }

  /**
   * Handle Google OAuth callback
   */
  async googleLogin(user) {
    // Update streak
    const { streak, isNewDay } = calculateStreak(user.lastLoginDate, new Date(), user.streak);
    user.streak = streak;
    if (streak > user.longestStreak) {
      user.longestStreak = streak;
    }

    if (isNewDay) {
      user.xp += XP_CONFIG.DAILY_LOGIN + (XP_CONFIG.STREAK_BONUS * streak);
      // Update daily login mission
      try {
        await missionService.updateProgress(user._id, 'daily_login');
      } catch (missionErr) {
        console.error('Error updating daily_login mission:', missionErr.message);
      }
    }

    user.lastLoginDate = new Date();
    user.lastActiveDate = new Date();

    // Generate tokens
    const tokens = generateTokenPair(user);
    user.refreshToken = tokens.refreshToken;

    await user.save();

    return {
      user: user.toJSON(),
      ...tokens,
    };
  }

  /**
   * Handle Google Mobile Sign-In (Native token)
   */
  async mobileGoogleLogin(idToken) {
    if (!idToken) {
      throw new AppError('idToken là bắt buộc', 400);
    }

    let decodedPayload;
    try {
      const jwt = require('jsonwebtoken');
      decodedPayload = jwt.decode(idToken);
      
      if (!decodedPayload) {
        // Fallback for custom client test tokens (mock format)
        if (idToken.startsWith('mock_')) {
          const parts = idToken.split('_');
          decodedPayload = {
            email: parts[1] || 'mock@gmail.com',
            name: parts[2] || 'Mock User',
            picture: '',
            sub: parts[3] || 'mock_google_id_123'
          };
        } else {
          throw new Error('Không thể decode idToken');
        }
      }
    } catch (err) {
      throw new AppError('Google idToken không hợp lệ hoặc sai định dạng', 400);
    }

    const { email, name, picture, sub: googleId } = decodedPayload;

    if (!email) {
      throw new AppError('Google Token không chứa địa chỉ Email', 400);
    }

    // Find or create user
    let user = await User.findOne({ 
      $or: [{ googleId }, { email }] 
    });

    if (!user) {
      // Create user if not exists
      user = await User.create({
        name: name || email.split('@')[0],
        email,
        googleId,
        avatar: picture || '',
        authProvider: AUTH_PROVIDERS.GOOGLE,
        isEmailVerified: true,
      });
    } else {
      // Update googleId and avatar if local user logs in with google first time
      if (!user.googleId) user.googleId = googleId;
      if (picture && !user.avatar) user.avatar = picture;
      user.authProvider = AUTH_PROVIDERS.GOOGLE;
    }

    // Update streak and logins
    const { streak, isNewDay } = calculateStreak(user.lastLoginDate, new Date(), user.streak);
    user.streak = streak;
    if (streak > user.longestStreak) {
      user.longestStreak = streak;
    }

    if (isNewDay) {
      user.xp += XP_CONFIG.DAILY_LOGIN + (XP_CONFIG.STREAK_BONUS * streak);
      // Update daily login mission
      try {
        await missionService.updateProgress(user._id, 'daily_login');
      } catch (missionErr) {
        console.error('Error updating daily_login mission:', missionErr.message);
      }
    }

    user.lastLoginDate = new Date();
    user.lastActiveDate = new Date();

    const tokens = generateTokenPair(user);
    user.refreshToken = tokens.refreshToken;

    await user.save();

    return {
      user: user.toJSON(),
      ...tokens,
    };
  }
}

module.exports = new AuthService();
