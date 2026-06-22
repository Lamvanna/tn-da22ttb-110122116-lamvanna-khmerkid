/**
 * ========================================
 * Game Service
 * ========================================
 */

const GameResult = require('../models/GameResult');
const userService = require('./userService');
const { calculateStars, calculateGameStars, calculateGameXP } = require('../utils/helpers');
const { XP_CONFIG } = require('../constants');

class GameService {
  /**
   * Save game result
   */
  async saveResult(userId, data, io = null) {
    const { gameType, score, level, time, correctAnswers, totalQuestions } = data;

    const stars = calculateGameStars(correctAnswers || 0, totalQuestions || 0, score);
    const xpEarned = calculateGameXP(stars);

    const result = await GameResult.create({
      userId,
      gameType,
      score,
      stars,
      level: level || 1,
      time: time || 0,
      correctAnswers: correctAnswers || 0,
      totalQuestions: totalQuestions || 0,
      xpEarned,
    });

    // Update user stats
    await userService.addXP(userId, xpEarned, io);
    await userService.addStars(userId, stars);

    // Increment total games played
    const User = require('../models/User');
    await User.findByIdAndUpdate(userId, {
      $inc: { 'learningProgress.totalGamesPlayed': 1 },
    });

    return {
      ...result.toObject(),
      xpEarned,
    };
  }

  /**
   * Get game history for user
   */
  async getHistory(userId, query = {}) {
    const filter = { userId };

    if (query.gameType) filter.gameType = query.gameType;

    const results = await GameResult.find(filter)
      .sort({ createdAt: -1 })
      .limit(parseInt(query.limit) || 20)
      .lean();

    return results;
  }

  /**
   * Get game statistics for user
   */
  async getStats(userId) {
    const stats = await GameResult.aggregate([
      { $match: { userId: require('mongoose').Types.ObjectId(userId) } },
      {
        $group: {
          _id: '$gameType',
          totalGames: { $sum: 1 },
          avgScore: { $avg: '$score' },
          maxScore: { $max: '$score' },
          totalStars: { $sum: '$stars' },
          totalTime: { $sum: '$time' },
        },
      },
    ]);

    return stats;
  }
}

module.exports = new GameService();
