/**
 * ========================================
 * Reading Service
 * ========================================
 */

const ReadingResult = require('../models/ReadingResult');
const Lesson = require('../models/Lesson');
const userService = require('./userService');
const missionService = require('./missionService');
const { calculateStars, isPassed } = require('../utils/helpers');
const { XP_CONFIG } = require('../constants');

class ReadingService {
  /**
   * Get reading lessons
   */
  async getReadingLessons(query = {}) {
    const filter = { isActive: true };

    if (query.difficulty) filter.difficulty = query.difficulty;
    if (query.type) filter.type = query.type;

    const lessons = await Lesson.find(filter)
      .select('title type difficulty khmerText romanized meaning readingLines audioUrl order')
      .sort({ order: 1 })
      .lean();

    return lessons;
  }

  /**
   * Save reading result
   */
  async saveResult(userId, data, io = null) {
    const { lessonId, timeSpent, linesCompleted } = data;
    // Hỗ trợ cả 2 format: wordsRead/totalWords (mới) và correctAnswers/totalQuestions (cũ)
    const wordsRead = data.wordsRead || data.correctAnswers || 0;
    const totalWords = data.totalWords || data.totalQuestions || 100;

    const accuracy = totalWords > 0
      ? Math.round((wordsRead / totalWords) * 100)
      : 0;
    const score = accuracy;
    const stars = calculateStars(score);
    const passed = isPassed(score);

    const result = await ReadingResult.create({
      userId,
      lessonId,
      score,
      accuracy,
      wordsRead,
      totalWords,
      timeSpent: timeSpent || 0,
      passed,
      linesCompleted: linesCompleted || [],
      xpEarned: XP_CONFIG.PER_READING,
    });

    // Update user stats
    if (!data.skipGamification) {
      await userService.addXP(userId, XP_CONFIG.PER_READING, io);
      await userService.addStars(userId, stars);
    }
    await userService.updateSkillProgress(userId, 'reading', score);

    if (passed && lessonId) {
      await userService.markLessonCompleted(userId, lessonId);
    }

    // Update mission progress for reading
    try {
      await missionService.updateProgress(userId, 'read_lesson');
    } catch (missionErr) {
      console.error('Error updating mission progress:', missionErr.message);
    }

    return {
      ...result.toObject(),
      stars,
    };
  }
}

module.exports = new ReadingService();
