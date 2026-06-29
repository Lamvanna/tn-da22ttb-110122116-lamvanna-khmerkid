/**
 * ========================================
 * Rank Service
 * ========================================
 */

const User = require('../models/User');
const GameResult = require('../models/GameResult');
const Progress = require('../models/Progress');
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
   * Combined from both mini-game results and completed lessons
   */
  async getWeeklyRanking(limit = 20) {
    const startOfWeek = getStartOfWeek();

    // 1. Game results
    const gameRanking = await GameResult.aggregate([
      { $match: { createdAt: { $gte: startOfWeek } } },
      {
        $group: {
          _id: '$userId',
          gameXp: { $sum: '$xpEarned' },
          gameStars: { $sum: '$stars' },
          gamesPlayed: { $sum: 1 }
        }
      }
    ]);

    // 2. Progress completed lessons
    const progressRanking = await Progress.aggregate([
      { $unwind: '$completedLessons' },
      { $match: { 'completedLessons.completedAt': { $gte: startOfWeek } } },
      {
        $group: {
          _id: '$userId',
          lessonStars: { $sum: '$completedLessons.stars' },
          lessonXp: {
            $sum: {
              $cond: [
                { $in: ["$completedLessons.lessonType", ["consonant", "vowel", "number"]] },
                55,
                {
                  $cond: [
                    { $in: ["$completedLessons.lessonType", ["spelling", "diacritical", "coeng", "closed_syllable"]] },
                    110,
                    { $multiply: [{ $ifNull: ["$completedLessons.stars", 0] }, 5] }
                  ]
                }
              ]
            }
          },
          lessonsCompleted: { $sum: 1 }
        }
      }
    ]);

    // 3. Combine both rankings
    const userMap = {};
    const allUsers = await User.find().select('name avatar level').lean();
    for (const user of allUsers) {
      userMap[user._id.toString()] = {
        userId: user._id,
        name: user.name,
        avatar: user.avatar,
        level: user.level,
        weeklyXp: 0,
        totalStars: 0,
        gamesPlayed: 0
      };
    }

    for (const row of gameRanking) {
      const uid = row._id.toString();
      if (userMap[uid]) {
        userMap[uid].weeklyXp += row.gameXp || 0;
        userMap[uid].totalStars += row.gameStars || 0;
        userMap[uid].gamesPlayed += row.gamesPlayed || 0;
      }
    }

    for (const row of progressRanking) {
      const uid = row._id.toString();
      if (userMap[uid]) {
        userMap[uid].weeklyXp += row.lessonXp || 0;
        userMap[uid].totalStars += row.lessonStars || 0;
        userMap[uid].gamesPlayed += row.lessonsCompleted || 0;
      }
    }

    const list = Object.values(userMap);
    list.sort((a, b) => b.weeklyXp - a.weeklyXp);

    return list.slice(0, limit).map((item, index) => ({
      rank: index + 1,
      ...item,
      stars: item.totalStars
    }));
  }

  /**
   * Get monthly ranking
   * Combined from both mini-game results and completed lessons
   */
  async getMonthlyRanking(limit = 20) {
    const startOfMonth = getStartOfMonth();

    // 1. Game results
    const gameRanking = await GameResult.aggregate([
      { $match: { createdAt: { $gte: startOfMonth } } },
      {
        $group: {
          _id: '$userId',
          gameXp: { $sum: '$xpEarned' },
          gameStars: { $sum: '$stars' },
          gamesPlayed: { $sum: 1 }
        }
      }
    ]);

    // 2. Progress completed lessons
    const progressRanking = await Progress.aggregate([
      { $unwind: '$completedLessons' },
      { $match: { 'completedLessons.completedAt': { $gte: startOfMonth } } },
      {
        $group: {
          _id: '$userId',
          lessonStars: { $sum: '$completedLessons.stars' },
          lessonXp: {
            $sum: {
              $cond: [
                { $in: ["$completedLessons.lessonType", ["consonant", "vowel", "number"]] },
                55,
                {
                  $cond: [
                    { $in: ["$completedLessons.lessonType", ["spelling", "diacritical", "coeng", "closed_syllable"]] },
                    110,
                    { $multiply: [{ $ifNull: ["$completedLessons.stars", 0] }, 5] }
                  ]
                }
              ]
            }
          },
          lessonsCompleted: { $sum: 1 }
        }
      }
    ]);

    // 3. Combine both rankings
    const userMap = {};
    const allUsers = await User.find().select('name avatar level').lean();
    for (const user of allUsers) {
      userMap[user._id.toString()] = {
        userId: user._id,
        name: user.name,
        avatar: user.avatar,
        level: user.level,
        monthlyXp: 0,
        totalStars: 0,
        gamesPlayed: 0
      };
    }

    for (const row of gameRanking) {
      const uid = row._id.toString();
      if (userMap[uid]) {
        userMap[uid].monthlyXp += row.gameXp || 0;
        userMap[uid].totalStars += row.gameStars || 0;
        userMap[uid].gamesPlayed += row.gamesPlayed || 0;
      }
    }

    for (const row of progressRanking) {
      const uid = row._id.toString();
      if (userMap[uid]) {
        userMap[uid].monthlyXp += row.lessonXp || 0;
        userMap[uid].totalStars += row.lessonStars || 0;
        userMap[uid].gamesPlayed += row.lessonsCompleted || 0;
      }
    }

    const list = Object.values(userMap);
    list.sort((a, b) => b.monthlyXp - a.monthlyXp);

    return list.slice(0, limit).map((item, index) => ({
      rank: index + 1,
      ...item,
      stars: item.totalStars
    }));
  }
}

module.exports = new RankService();
