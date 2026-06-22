/**
 * ========================================
 * Listening Service
 * ========================================
 */

const ListeningResult = require('../models/ListeningResult');
const Lesson = require('../models/Lesson');
const userService = require('./userService');
const missionService = require('./missionService');
const { calculateStars, isPassed } = require('../utils/helpers');
const { XP_CONFIG, MESSAGES } = require('../constants');
const { AppError } = require('../middlewares/errorHandler');

class ListeningService {
  /**
   * Get listening lessons
   */
  async getListeningLessons(query = {}) {
    const filter = { isActive: true, 'questions.0': { $exists: true } };

    if (query.difficulty) filter.difficulty = query.difficulty;

    const lessons = await Lesson.find(filter)
      .select('title type difficulty questions khmerText romanized meaning audioUrl order')
      .sort({ order: 1 })
      .lean();

    return lessons;
  }

  /**
   * Save listening result
   */
  async saveResult(userId, data, io = null) {
    const { lessonId, answers, correctAnswers, totalQuestions } = data;

    // Calculate score
    const score = totalQuestions > 0
      ? Math.round((correctAnswers / totalQuestions) * 100)
      : 0;
    const stars = calculateStars(score);
    const passed = isPassed(score);

    // Save result
    const result = await ListeningResult.create({
      userId,
      lessonId,
      score,
      correctAnswers,
      totalQuestions,
      passed,
      answers,
      xpEarned: XP_CONFIG.PER_LISTENING,
    });

    // Update user XP and skill progress
    if (!data.skipGamification) {
      await userService.addXP(userId, XP_CONFIG.PER_LISTENING, io);
      await userService.addStars(userId, stars);
    }
    await userService.updateSkillProgress(userId, 'listening', score);

    if (passed && lessonId) {
      await userService.markLessonCompleted(userId, lessonId);
    }

    // Update mission progress for listening
    try {
      await missionService.updateProgress(userId, 'listen_lesson');
    } catch (missionErr) {
      console.error('Error updating mission progress:', missionErr.message);
    }

    return {
      ...result.toObject(),
      stars,
    };
  }

  /**
   * Get user's listening history
   */
  async getHistory(userId, query = {}) {
    const results = await ListeningResult.find({ userId })
      .populate('lessonId', 'title type')
      .sort({ createdAt: -1 })
      .limit(parseInt(query.limit) || 20)
      .lean();

    return results;
  }
}

module.exports = new ListeningService();
