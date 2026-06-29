/**
 * ========================================
 * Badge Service
 * ========================================
 */

const Badge = require('../models/Badge');
const Achievement = require('../models/Achievement');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { NOTIFICATION_TYPES, SOCKET_EVENTS } = require('../constants');

class BadgeService {
  /**
   * Get all badges
   */
  async getAllBadges() {
    return await Badge.find({ isActive: true }).sort({ order: 1 }).lean();
  }

  /**
   * Get user's achievements
   */
  async getUserAchievements(userId) {
    const achievements = await Achievement.find({ userId })
      .populate('badgeId')
      .sort({ unlockedAt: -1 })
      .lean();

    return achievements;
  }

  /**
   * Check and unlock badges for a user
   * Called after XP/level/streak updates
   */
  async checkAndUnlockBadges(userId, io = null) {
    const user = await User.findById(userId);
    if (!user) return [];

    const allBadges = await Badge.find({ isActive: true });
    const unlockedBadges = [];

    for (const badge of allBadges) {
      // Skip if already has badge
      if (user.badges.includes(badge._id)) continue;

      // Check requirement
      const isEligible = this._checkRequirement(user, badge);

      if (isEligible) {
        // Unlock badge
        await this._unlockBadge(user, badge, io);
        unlockedBadges.push(badge);
      }
    }

    return unlockedBadges;
  }

  /**
   * Check if user meets badge requirement
   */
  _checkRequirement(user, badge) {
    if (!badge.requirement || !badge.requirement.type) return false;

    const { type, value } = badge.requirement;

    switch (type) {
      case 'level_reach':
        return user.level >= value;

      case 'streak_days':
        return user.streak >= value;

      case 'lessons_complete':
        return (user.learningProgress?.totalLessonsCompleted || 0) >= value;

      case 'games_played':
        return (user.learningProgress?.totalGamesPlayed || 0) >= value;

      case 'xp_total':
        return user.xp >= value;

      case 'stars_total':
        return user.stars >= value;

      case 'speaking_level':
        return (user.learningProgress?.speakingLevel || 0) >= value;

      case 'listening_level':
        return (user.learningProgress?.listeningLevel || 0) >= value;

      case 'reading_level':
        return (user.learningProgress?.readingLevel || 0) >= value;

      case 'writing_level':
        return (user.learningProgress?.writingLevel || 0) >= value;

      // New requirement types (activity counters)
      case 'writing_practice':
        return (user.learningProgress?.writingPracticeCount || 0) >= value;

      case 'reading_correct':
        return (user.learningProgress?.readingCorrectCount || 0) >= value;

      case 'speaking_success':
        return (user.learningProgress?.speakingSuccessCount || 0) >= value;

      case 'listening_complete':
        return (user.learningProgress?.listeningCompleteCount || 0) >= value;

      case 'reading_lessons_complete':
        return (user.learningProgress?.readingLessonsCompleted || 0) >= value;

      case 'content_complete':
        // Kiểm tra hoàn thành 100% nội dung: tất cả kỹ năng level >= 90
        return (user.learningProgress?.writingLevel || 0) >= 90
            && (user.learningProgress?.readingLevel || 0) >= 90
            && (user.learningProgress?.speakingLevel || 0) >= 90
            && (user.learningProgress?.listeningLevel || 0) >= 90;

      default:
        return false;
    }
  }

  /**
   * Unlock a badge for user
   */
  async _unlockBadge(user, badge, io = null) {
    // Add badge to user
    user.badges.push(badge._id);

    // Award XP and stars
    if (badge.xpReward) user.xp += badge.xpReward;
    if (badge.starsReward) user.stars += badge.starsReward;

    await user.save();

    // Create achievement record
    await Achievement.findOneAndUpdate(
      { userId: user._id, badgeId: badge._id },
      {
        userId: user._id,
        badgeId: badge._id,
        progress: 100,
        isUnlocked: true,
        unlockedAt: new Date(),
      },
      { upsert: true, new: true }
    );

    // Create notification
    await Notification.create({
      userId: user._id,
      title: 'Huy hiệu mới! 🏆',
      message: `Chúc mừng! Bạn đã mở khóa huy hiệu "${badge.name}"!`,
      type: NOTIFICATION_TYPES.BADGE_UNLOCKED,
      data: { badgeId: badge._id, badgeName: badge.name },
    });

    // Emit realtime event
    if (io) {
      io.to(user._id.toString()).emit(SOCKET_EVENTS.BADGE_UNLOCK, {
        badge: badge.toObject(),
        xpReward: badge.xpReward,
        starsReward: badge.starsReward,
      });
    }
  }
}

module.exports = new BadgeService();
