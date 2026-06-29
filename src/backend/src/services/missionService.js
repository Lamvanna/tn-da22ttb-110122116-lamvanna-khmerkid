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
   * Get all active missions with user progress.
   * Daily: exactly 3 random missions assigned per day (persistent).
   * Weekly: all weekly missions.
   */
  async getMissions(userId) {
    const allMissions = await Mission.find({ isActive: true }).sort({ order: 1 }).lean();
    const { endOfDay } = getTodayRange();
    const now = new Date();

    const dailyMissions = allMissions.filter(m => m.type === MISSION_TYPES.DAILY);
    const weeklyMissions = allMissions.filter(m => m.type === MISSION_TYPES.WEEKLY);

    // ── Daily: assign exactly 3 random missions per day ──
    // Check if user already has daily assignments for today
    const existingDailyProgress = await MissionProgress.find({
      userId,
      missionId: { $in: dailyMissions.map(m => m._id) },
      expiresAt: { $gte: now },
    }).lean();

    let assignedDailyIds;

    if (existingDailyProgress.length > 3) {
      // Old data has too many entries — keep 3, prioritize ones with progress
      const sorted = [...existingDailyProgress].sort((a, b) => {
        // Prioritize: claimed > completed > has progress > no progress
        if (a.isClaimed !== b.isClaimed) return b.isClaimed ? 1 : -1;
        if (a.isCompleted !== b.isCompleted) return b.isCompleted ? 1 : -1;
        return (b.progress || 0) - (a.progress || 0);
      });
      const keep = sorted.slice(0, 3);
      const remove = sorted.slice(3);
      assignedDailyIds = keep.map(p => p.missionId.toString());

      // Clean up extra entries
      if (remove.length > 0) {
        await MissionProgress.deleteMany({
          _id: { $in: remove.map(p => p._id) },
        });
      }
    } else if (existingDailyProgress.length < 3) {
      assignedDailyIds = existingDailyProgress.map(p => p.missionId.toString());
      // Pick random missions that haven't been assigned yet
      const unassigned = dailyMissions.filter(
        m => !assignedDailyIds.includes(m._id.toString())
      );
      const needed = 3 - assignedDailyIds.length;
      const shuffled = unassigned.sort(() => Math.random() - 0.5);
      const newPicks = shuffled.slice(0, needed);

      for (const mission of newPicks) {
        await MissionProgress.create({
          userId,
          missionId: mission._id,
          progress: 0,
          expiresAt: endOfDay,
        });
        assignedDailyIds.push(mission._id.toString());
      }
    } else {
      // Exactly 3
      assignedDailyIds = existingDailyProgress.map(p => p.missionId.toString());
    }

    // Build the assigned daily missions list with progress
    const assignedDailyMissions = dailyMissions.filter(
      m => assignedDailyIds.includes(m._id.toString())
    );

    const dailyWithProgress = await Promise.all(
      assignedDailyMissions.map(async (mission) => {
        const progress = await MissionProgress.findOne({
          userId,
          missionId: mission._id,
          expiresAt: { $gte: now },
        });

        return {
          ...mission,
          progress: progress ? progress.progress : 0,
          isCompleted: progress ? progress.isCompleted : false,
          isClaimed: progress ? progress.isClaimed : false,
        };
      })
    );

    // ── Weekly: return all with progress ──
    const weeklyWithProgress = await Promise.all(
      weeklyMissions.map(async (mission) => {
        let progress = await MissionProgress.findOne({
          userId,
          missionId: mission._id,
          expiresAt: { $gte: now },
        });

        if (!progress) {
          progress = await MissionProgress.create({
            userId,
            missionId: mission._id,
            progress: 0,
            expiresAt: this._getEndOfWeek(),
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

    return [...dailyWithProgress, ...weeklyWithProgress];
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
        // Only create progress if user hasn't been assigned this daily mission
        // For weekly missions, always create
        if (mission.type === MISSION_TYPES.DAILY) {
          // Skip — daily missions not assigned to this user today
          continue;
        }
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
