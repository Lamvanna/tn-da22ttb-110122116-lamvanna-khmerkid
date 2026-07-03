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
      // Permanent item: check if it's a real single-owned permanent item
      const singleOwnedItems = [
        'voi_hieu_hoc', 'khi_tinh_nghich', 'ho_dung_cam', 'rua_kien_tri', 'cu_thong_thai', 'but_than_ky'
      ];
      if (singleOwnedItems.includes(itemId)) {
        if (user.purchasedItems && user.purchasedItems.includes(itemId)) {
          throw new AppError('Bạn đã sở hữu vật phẩm này rồi!', 400);
        }
        updateOps.$addToSet = { purchasedItems: itemId };
      } else {
        // Cho phép mua nhiều rương hoặc chuỗi dự phòng và lưu tích lũy vào mảng
        updateOps.$push = { purchasedItems: itemId };
      }
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

  /**
   * Sử dụng một vật phẩm permanent (Rương kim cương hoặc Chuỗi dự phòng)
   * Xóa vật phẩm khỏi purchasedItems, áp dụng hiệu ứng phần thưởng và lưu vào CSDL
   */
  async usePermanentItem(userId, itemId) {
    const user = await User.findById(userId);
    if (!user) throw new AppError('Người dùng không tồn tại!', 404);

    if (!user.purchasedItems || !user.purchasedItems.includes(itemId)) {
      throw new AppError('Bạn không sở hữu vật phẩm này!', 400);
    }

    // Xóa ĐÚNG 1 phần tử ra khỏi mảng purchasedItems thay vì dùng $pull (xóa tất cả)
    const index = user.purchasedItems.indexOf(itemId);
    if (index > -1) {
      user.purchasedItems.splice(index, 1);
    }
    
    // Đánh dấu mảng purchasedItems là đã thay đổi để Mongoose nhận biết và lưu lại
    user.markModified('purchasedItems');

    const updateOps = {};
    
    // Tỷ lệ 5% mở ra nhân vật chưa sở hữu khi mở bất kỳ phần quà nào
    let characterUnlocked = null;
    const isChestOrBadge = ['ruong_kim_cuong', 'huy_hieu_sieu_sao', 'qua_cau_tuyet', 'sach_tri_thuc', 'khinh_khi_cau'].includes(itemId);
    
    if (isChestOrBadge && Math.random() < 0.10) {
      const allCharacters = ['voi_hieu_hoc', 'khi_tinh_nghich', 'ho_dung_cam', 'rua_kien_tri', 'cu_thong_thai'];
      // Lọc các nhân vật chưa sở hữu trong mảng purchasedItems của user
      const unowned = allCharacters.filter(c => !user.purchasedItems.includes(c));
      if (unowned.length > 0) {
        characterUnlocked = unowned[Math.floor(Math.random() * unowned.length)];
        user.purchasedItems.push(characterUnlocked);
      }
    }

    let reward = null;

    if (itemId === 'ruong_kim_cuong') {
      // Mở Rương kim cương: Tặng ngẫu nhiên sao, XP và các vật phẩm
      const earnedStars = Math.floor(Math.random() * 101) + 100; // 100 - 200 sao
      const earnedXp = Math.floor(Math.random() * 201) + 300;     // 300 - 500 XP
      
      user.stars = (user.stars || 0) + earnedStars;
      user.xp = (user.xp || 0) + earnedXp;
      
      if (!user.inventory) user.inventory = {};
      user.inventory.hints = (user.inventory.hints || 0) + 3;
      user.inventory.livesPowerups = (user.inventory.livesPowerups || 0) + 2;

      reward = {
        type: 'ruong_kim_cuong',
        stars: earnedStars,
        xp: earnedXp,
        hints: 3,
        lives: 2,
        doubleScore: 0,
        time: 0,
        characterUnlocked,
      };
    } else if (itemId === 'huy_hieu_sieu_sao') {
      // Huy hiệu siêu sao: Tập trung vào Sao, XP và Nhân đôi điểm
      const earnedStars = Math.floor(Math.random() * 101) + 150; // 150 - 250 sao
      const earnedXp = Math.floor(Math.random() * 201) + 200;     // 200 - 400 XP
      
      user.stars = (user.stars || 0) + earnedStars;
      user.xp = (user.xp || 0) + earnedXp;
      
      if (!user.inventory) user.inventory = {};
      user.inventory.doubleScorePowerups = (user.inventory.doubleScorePowerups || 0) + 2;
      user.inventory.hints = (user.inventory.hints || 0) + 1;

      reward = {
        type: 'huy_hieu_sieu_sao',
        stars: earnedStars,
        xp: earnedXp,
        hints: 1,
        lives: 0,
        doubleScore: 2,
        time: 0,
        characterUnlocked,
      };
    } else if (itemId === 'qua_cau_tuyet') {
      // Quả cầu tuyết: Tập trung vào Đóng băng thời gian và Thêm lượt chơi
      const earnedStars = Math.floor(Math.random() * 71) + 80;    // 80 - 150 sao
      const earnedXp = Math.floor(Math.random() * 151) + 150;     // 150 - 300 XP
      
      user.stars = (user.stars || 0) + earnedStars;
      user.xp = (user.xp || 0) + earnedXp;
      
      if (!user.inventory) user.inventory = {};
      user.inventory.timePowerups = (user.inventory.timePowerups || 0) + 3;
      user.inventory.livesPowerups = (user.inventory.livesPowerups || 0) + 1;

      reward = {
        type: 'qua_cau_tuyet',
        stars: earnedStars,
        xp: earnedXp,
        hints: 0,
        lives: 1,
        doubleScore: 0,
        time: 3,
        characterUnlocked,
      };
    } else if (itemId === 'sach_tri_thuc') {
      // Sách tri thức: Tặng cực nhiều XP và Gợi ý học tập
      const earnedStars = Math.floor(Math.random() * 101) + 200; // 200 - 300 sao
      const earnedXp = Math.floor(Math.random() * 301) + 500;     // 500 - 800 XP
      
      user.stars = (user.stars || 0) + earnedStars;
      user.xp = (user.xp || 0) + earnedXp;
      
      if (!user.inventory) user.inventory = {};
      user.inventory.hints = (user.inventory.hints || 0) + 3;
      user.inventory.timePowerups = (user.inventory.timePowerups || 0) + 1;

      reward = {
        type: 'sach_tri_thuc',
        stars: earnedStars,
        xp: earnedXp,
        hints: 3,
        lives: 0,
        doubleScore: 0,
        time: 1,
        characterUnlocked,
      };
    } else if (itemId === 'khinh_khi_cau') {
      // Khinh khí cầu: Tặng ngẫu nhiên nhiều sao và Thêm lượt chơi
      const earnedStars = Math.floor(Math.random() * 201) + 300; // 300 - 500 sao
      const earnedXp = Math.floor(Math.random() * 201) + 400;     // 400 - 600 XP
      
      user.stars = (user.stars || 0) + earnedStars;
      user.xp = (user.xp || 0) + earnedXp;
      
      if (!user.inventory) user.inventory = {};
      user.inventory.livesPowerups = (user.inventory.livesPowerups || 0) + 3;
      user.inventory.doubleScorePowerups = (user.inventory.doubleScorePowerups || 0) + 1;

      reward = {
        type: 'khinh_khi_cau',
        stars: earnedStars,
        xp: earnedXp,
        hints: 0,
        lives: 3,
        doubleScore: 1,
        time: 0,
        characterUnlocked,
      };
    } else if (itemId === 'streak_freeze') {
      // Dùng Chuỗi dự phòng: Lùi ngày lastLoginDate về hôm qua (giúp bảo toàn/cứu streak)
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      user.lastLoginDate = yesterday;

      reward = {
        type: 'streak_freeze',
        message: 'Đã kích hoạt Chuỗi dự phòng thành công! Ngày học cuối cùng của bạn đã được lùi về ngày hôm qua để bảo toàn Streak của bạn.',
      };
    } else {
      reward = {
        type: 'other',
        message: 'Đã sử dụng vật phẩm thành công!',
      };
    }

    const updatedUser = await user.save();

    return {
      user: {
        stars: updatedUser.stars,
        xp: updatedUser.xp,
        purchasedItems: updatedUser.purchasedItems || [],
        inventory: updatedUser.inventory,
        lastLoginDate: updatedUser.lastLoginDate,
      },
      reward,
    };
  }
}

module.exports = new UserService();
