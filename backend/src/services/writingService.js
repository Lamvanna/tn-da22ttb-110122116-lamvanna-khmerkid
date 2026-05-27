/**
 * ========================================
 * Writing Service
 * ========================================
 */

const WritingResult = require('../models/WritingResult');
const userService = require('./userService');
const { calculateStars, isPassed } = require('../utils/helpers');
const { XP_CONFIG } = require('../constants');

class WritingService {
  /**
   * Check writing (AI Stub for handwriting recognition)
   */
  async checkWriting(userId, data, io = null) {
    const { lessonId, imageUrl, imagePublicId, score: clientScore } = data;

    // Use client-provided score (from on-device stroke checking)
    // or stub a score if not provided
    const score = clientScore || this._stubWritingScore();
    const accuracy = score;
    const passed = isPassed(score);
    const stars = calculateStars(score);

    const result = await WritingResult.create({
      userId,
      lessonId,
      imageUrl: imageUrl || '',
      imagePublicId: imagePublicId || '',
      score,
      accuracy,
      strokeOrderCorrect: score >= 70,
      passed,
      xpEarned: XP_CONFIG.PER_WRITING,
      feedback: this._generateFeedback(score),
    });

    // Update user stats
    await userService.addXP(userId, XP_CONFIG.PER_WRITING, io);
    await userService.addStars(userId, stars);
    await userService.updateSkillProgress(userId, 'writing', score);

    if (passed && lessonId) {
      await userService.markLessonCompleted(userId, lessonId);
    }

    return {
      ...result.toObject(),
      stars,
    };
  }

  /**
   * Save writing result (without checking)
   */
  async saveResult(userId, data) {
    const result = await WritingResult.create({
      userId,
      ...data,
    });
    return result;
  }

  /**
   * STUB: Generate random writing score
   */
  _stubWritingScore() {
    return Math.floor(Math.random() * 40) + 60; // 60-100
  }

  /**
   * Generate feedback based on score
   */
  _generateFeedback(score) {
    if (score >= 90) return 'Tuyệt vời! Nét chữ rất đẹp! 🌟';
    if (score >= 70) return 'Tốt lắm! Cần cải thiện thêm một chút nữa.';
    if (score >= 50) return 'Khá ổn. Hãy luyện thêm thứ tự nét nhé!';
    return 'Cần luyện thêm nhiều. Hãy xem lại hướng dẫn nét chữ.';
  }
}

module.exports = new WritingService();
