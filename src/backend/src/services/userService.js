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
    // Sync completed lessons from Progress collection to User collection to ensure consistency
    try {
      const Progress = require('../models/Progress');
      const progress = await Progress.findOne({ userId });
      if (progress && progress.completedLessons && progress.completedLessons.length > 0) {
        const validObjectIds = progress.completedLessons
          .map(l => l.lessonId)
          .filter(id => id && id.match(/^[0-9a-fA-F]{24}$/));
        
        if (validObjectIds.length > 0) {
          await User.findByIdAndUpdate(userId, {
            $addToSet: { 'learningProgress.completedLessons': { $each: validObjectIds } },
            'learningProgress.totalLessonsCompleted': progress.completedLessons.filter(l => l.isCompleted).length
          });
        }
      }
    } catch (err) {
      console.error('Error syncing progress to user profile:', err);
    }

    const user = await User.findById(userId)
      .populate('badges')
      .populate('achievements')
      .populate('learningProgress.completedLessons');

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
   * Update user inventory
   */
  async updateInventory(userId, inventoryData) {
    const user = await User.findByIdAndUpdate(
      userId,
      { $set: { inventory: inventoryData } },
      { new: true, runValidators: true }
    );
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
   * Purchase a shop item - atomic operation
   * Deducts stars, adds item/powerup to user's inventory
   */
  async purchaseItem(userId, { itemId, itemType, price, powerUpType }) {
    const user = await User.findById(userId);
    if (!user) throw new AppError(MESSAGES.USER_NOT_FOUND, 404);

    // Check enough stars
    if ((user.stars || 0) < price) {
      throw new AppError('Không đủ sao để mua vật phẩm!', 400);
    }

    // Deduct stars atomically
    const updateOps = {
      $inc: { stars: -price },
    };

    if (itemType === 'consumable') {
      // Consumable: increment the corresponding powerup in inventory
      const powerUpMap = {
        'pu_hint': 'inventory.hints',
        'pu_time': 'inventory.timePowerups',
        'pu_live': 'inventory.livesPowerups',
        'pu_double': 'inventory.doubleScorePowerups',
      };
      const field = powerUpMap[powerUpType];
      if (field) {
        updateOps.$inc[field] = 1;
      }
    } else {
      // Permanent item: add to purchasedItems if not already owned
      if (user.purchasedItems && user.purchasedItems.includes(itemId)) {
        throw new AppError('Bạn đã sở hữu vật phẩm này rồi!', 400);
      }
      updateOps.$addToSet = { purchasedItems: itemId };
    }

    const updatedUser = await User.findByIdAndUpdate(userId, updateOps, { new: true });
    if (!updatedUser) throw new AppError(MESSAGES.USER_NOT_FOUND, 404);

    return {
      stars: updatedUser.stars,
      purchasedItems: updatedUser.purchasedItems || [],
      inventory: updatedUser.inventory,
    };
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
    await User.findOneAndUpdate(
      {
        _id: userId,
        'learningProgress.completedLessons': { $ne: lessonId }
      },
      {
        $addToSet: { 'learningProgress.completedLessons': lessonId },
        $inc: { 'learningProgress.totalLessonsCompleted': 1 },
      }
    );
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
