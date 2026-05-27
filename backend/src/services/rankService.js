/**
 * ========================================
 * Rank Service
 * ========================================
 */

const User = require('../models/User');
const GameResult = require('../models/GameResult');
const { getStartOfWeek, getStartOfMonth } = require('../utils/helpers');

class RankService {
  /**
   * Get top global ranking
   */
  async getTopRanking(limit = 20) {
    const users = await User.find()
      .select('name avatar level xp stars streak')
      .sort({ xp: -1 })
      .limit(limit)
      .lean();

    return users.map((user, index) => ({
      rank: index + 1,
      ...user,
    }));
  }

  /**
   * Get weekly ranking (based on XP earned this week)
   * Using game results + learning results as proxy
   */
  async getWeeklyRanking(limit = 20) {
    const startOfWeek = getStartOfWeek();

    const ranking = await GameResult.aggregate([
      {
        $match: {
          createdAt: { $gte: startOfWeek },
        },
      },
      {
        $group: {
          _id: '$userId',
          weeklyXp: { $sum: '$xpEarned' },
          gamesPlayed: { $sum: 1 },
          totalStars: { $sum: '$stars' },
        },
      },
      { $sort: { weeklyXp: -1 } },
      { $limit: limit },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'user',
          pipeline: [
            { $project: { name: 1, avatar: 1, level: 1 } },
          ],
        },
      },
      { $unwind: '$user' },
      {
        $project: {
          userId: '$_id',
          name: '$user.name',
          avatar: '$user.avatar',
          level: '$user.level',
          weeklyXp: 1,
          gamesPlayed: 1,
          totalStars: 1,
        },
      },
    ]);

    return ranking.map((item, index) => ({
      rank: index + 1,
      ...item,
    }));
  }

  /**
   * Get monthly ranking
   */
  async getMonthlyRanking(limit = 20) {
    const startOfMonth = getStartOfMonth();

    const ranking = await GameResult.aggregate([
      {
        $match: {
          createdAt: { $gte: startOfMonth },
        },
      },
      {
        $group: {
          _id: '$userId',
          monthlyXp: { $sum: '$xpEarned' },
          gamesPlayed: { $sum: 1 },
          totalStars: { $sum: '$stars' },
        },
      },
      { $sort: { monthlyXp: -1 } },
      { $limit: limit },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'user',
          pipeline: [
            { $project: { name: 1, avatar: 1, level: 1 } },
          ],
        },
      },
      { $unwind: '$user' },
      {
        $project: {
          userId: '$_id',
          name: '$user.name',
          avatar: '$user.avatar',
          level: '$user.level',
          monthlyXp: 1,
          gamesPlayed: 1,
          totalStars: 1,
        },
      },
    ]);

    return ranking.map((item, index) => ({
      rank: index + 1,
      ...item,
    }));
  }
}

module.exports = new RankService();
