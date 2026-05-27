/**
 * ========================================
 * Mission Service
 * ========================================
 */

const Mission = require('../models/Mission');
const MissionProgress = require('../models/MissionProgress');
const User = require('../models/User');
const { AppError } = require('../middlewares/errorHandler');
const { MESSAGES, MISSION_TYPES } = require('../constants');
const { getTodayRange, getStartOfWeek } = require('../utils/helpers');

class MissionService {
  /**
   * Get all active missions with user progress
   */
  async getMissions(userId) {
    const missions = await Mission.find({ isActive: true }).sort({ order: 1 }).lean();
    const { endOfDay } = getTodayRange();

    // Get or create progress for each mission
    const missionsWithProgress = await Promise.all(
      missions.map(async (mission) => {
        let progress = await MissionProgress.findOne({
          userId,
          missionId: mission._id,
          expiresAt: { $gte: new Date() },
        });

        if (!progress) {
          // Create new progress entry
          const expiresAt = mission.type === MISSION_TYPES.DAILY
            ? endOfDay
            : this._getEndOfWeek();

          progress = await MissionProgress.create({
            userId,
            missionId: mission._id,
            progress: 0,
            expiresAt,
          });
        }

        return {
          ...mission,
          progress: progress.progress,
          isCompleted: progress.isCompleted,
          isClaimed: progress.isClaimed,
        };
      })
    );

    return missionsWithProgress;
  }

  /**
   * Update mission progress for a specific action
   */
  async updateProgress(userId, action, amount = 1) {
    // Find missions matching this action
    const missions = await Mission.find({ action, isActive: true });

    for (const mission of missions) {
      let progress = await MissionProgress.findOne({
        userId,
        missionId: mission._id,
        expiresAt: { $gte: new Date() },
      });

      if (!progress) {
        const { endOfDay } = getTodayRange();
        progress = await MissionProgress.create({
          userId,
          missionId: mission._id,
          progress: 0,
          expiresAt: mission.type === MISSION_TYPES.DAILY ? endOfDay : this._getEndOfWeek(),
        });
      }

      if (!progress.isCompleted) {
        progress.progress = Math.min(progress.progress + amount, mission.requirement);
        progress.isCompleted = progress.progress >= mission.requirement;
        await progress.save();
      }
    }
  }

  /**
   * Claim mission reward
   */
  async claimReward(userId, missionId) {
    const mission = await Mission.findById(missionId);
    if (!mission) throw new AppError(MESSAGES.NOT_FOUND, 404);

    const progress = await MissionProgress.findOne({
      userId,
      missionId,
      expiresAt: { $gte: new Date() },
    });

    if (!progress) throw new AppError(MESSAGES.NOT_FOUND, 404);
    if (!progress.isCompleted) throw new AppError(MESSAGES.MISSION_NOT_COMPLETED, 400);
    if (progress.isClaimed) throw new AppError(MESSAGES.MISSION_ALREADY_CLAIMED, 400);

    // Mark as claimed
    progress.isClaimed = true;
    progress.claimedAt = new Date();
    await progress.save();

    // Award rewards
    const user = await User.findById(userId);
    if (mission.reward.xp) user.xp += mission.reward.xp;
    if (mission.reward.stars) user.stars += mission.reward.stars;
    await user.save();

    return {
      reward: mission.reward,
      user: user.toJSON(),
    };
  }

  /**
   * Get end of current week (Sunday 23:59:59)
   */
  _getEndOfWeek() {
    const now = new Date();
    const day = now.getDay();
    const daysUntilSunday = day === 0 ? 0 : 7 - day;
    const endOfWeek = new Date(now);
    endOfWeek.setDate(endOfWeek.getDate() + daysUntilSunday);
    endOfWeek.setHours(23, 59, 59, 999);
    return endOfWeek;
  }
}

module.exports = new MissionService();
