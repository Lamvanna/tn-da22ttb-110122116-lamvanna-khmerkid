/**
 * ========================================
 * User Service
 * ========================================
 * 
 * Business logic for user profile,
 * XP management, and level progression.
 */

const User = require('../models/User');
const { calculateLevel, calculateStreak } = require('../utils/helpers');
const { AppError } = require('../middlewares/errorHandler');
const { MESSAGES, SOCKET_EVENTS } = require('../constants');

class UserService {
  /**
   * Get user profile by ID
   */
  async getProfile(userId) {
    const user = await User.findById(userId)
      .populate('badges')
      .populate('achievements');

    if (!user) {
      throw new AppError(MESSAGES.USER_NOT_FOUND, 404);
    }

    // Calculate level info
    const levelInfo = calculateLevel(user.xp);

    return {
      ...user.toJSON(),
      levelInfo,
    };
  }

  /**
   * Update user profile
   */
  async updateProfile(userId, updateData) {
    // Only allow certain fields to be updated
    const allowedFields = ['name', 'avatar'];
    const filteredData = {};

    Object.keys(updateData).forEach((key) => {
      if (allowedFields.includes(key)) {
        filteredData[key] = updateData[key];
      }
    });

    const user = await User.findByIdAndUpdate(userId, filteredData, {
      new: true,
      runValidators: true,
    });

    if (!user) {
      throw new AppError(MESSAGES.USER_NOT_FOUND, 404);
    }

    return user.toJSON();
  }

  /**
   * Add XP to user and check for level up
   * @param {string} userId - User ID
   * @param {number} xpAmount - XP to add
   * @param {Object} io - Socket.io instance (optional)
   * @returns {Object} { user, leveledUp, newLevel }
   */
  async addXP(userId, xpAmount, io = null) {
    const user = await User.findById(userId);
    if (!user) throw new AppError(MESSAGES.USER_NOT_FOUND, 404);

    const oldLevel = calculateLevel(user.xp).level;
    user.xp += xpAmount;
    const newLevelInfo = calculateLevel(user.xp);
    const leveledUp = newLevelInfo.level > oldLevel;

    if (leveledUp) {
      user.level = newLevelInfo.level;
    }

    await user.save();

    // Emit realtime events
    if (io) {
      io.to(userId.toString()).emit(SOCKET_EVENTS.XP_UPDATE, {
        xp: user.xp,
        xpAdded: xpAmount,
        levelInfo: newLevelInfo,
      });

      if (leveledUp) {
        io.to(userId.toString()).emit(SOCKET_EVENTS.LEVEL_UPDATE, {
          level: newLevelInfo.level,
          previousLevel: oldLevel,
        });
      }
    }

    return { user, leveledUp, newLevel: newLevelInfo.level };
  }

  /**
   * Add stars to user
   */
  async addStars(userId, starsAmount) {
    const user = await User.findByIdAndUpdate(
      userId,
      { $inc: { stars: starsAmount } },
      { new: true }
    );

    if (!user) throw new AppError(MESSAGES.USER_NOT_FOUND, 404);
    return user;
  }

  /**
   * Update learning progress for a skill
   */
  async updateSkillProgress(userId, skill, score) {
    const fieldMap = {
      listening: 'learningProgress.listeningLevel',
      speaking: 'learningProgress.speakingLevel',
      reading: 'learningProgress.readingLevel',
      writing: 'learningProgress.writingLevel',
    };

    const field = fieldMap[skill];
    if (!field) throw new AppError('Skill không hợp lệ', 400);

    // Get current skill level, update with weighted average
    const user = await User.findById(userId);
    if (!user) throw new AppError(MESSAGES.USER_NOT_FOUND, 404);

    const currentLevel = user.learningProgress[`${skill}Level`] || 0;
    // Weighted average: 70% old + 30% new score
    const newLevel = Math.round(currentLevel * 0.7 + score * 0.3);

    await User.findByIdAndUpdate(userId, {
      [field]: Math.min(100, newLevel),
      'learningProgress.lastPracticed': new Date(),
    });

    return newLevel;
  }

  /**
   * Mark lesson as completed
   */
  async markLessonCompleted(userId, lessonId) {
    await User.findByIdAndUpdate(userId, {
      $addToSet: { 'learningProgress.completedLessons': lessonId },
      $inc: { 'learningProgress.totalLessonsCompleted': 1 },
    });
  }

  /**
   * Get user's rank position
   */
  async getUserRank(userId) {
    const user = await User.findById(userId);
    if (!user) throw new AppError(MESSAGES.USER_NOT_FOUND, 404);

    // Count users with more XP
    const rank = await User.countDocuments({ xp: { $gt: user.xp } }) + 1;

    return {
      rank,
      xp: user.xp,
      level: user.level,
      name: user.name,
      avatar: user.avatar,
    };
  }
}

module.exports = new UserService();
