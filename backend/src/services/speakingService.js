/**
 * ========================================
 * Speaking Service
 * ========================================
 * 
 * Pronunciation checking with AI stub,
 * audio upload, and result saving.
 */

const SpeakingResult = require('../models/SpeakingResult');
const userService = require('./userService');
const { calculateStars, isPassed } = require('../utils/helpers');
const { XP_CONFIG, STARS_CONFIG } = require('../constants');

class SpeakingService {
  /**
   * Check pronunciation (AI Stub)
   * In production, integrate with Google Cloud Speech-to-Text
   * or a custom Khmer speech recognition API.
   */
  async checkPronunciation(userId, data, io = null) {
    const { lessonId, referenceText, recognizedText, audioUrl, audioPublicId } = data;

    // ========================================
    // AI STUB - Pronunciation Scoring
    // Replace this with actual AI integration
    // ========================================
    const scoringResult = this._stubPronunciationScoring(referenceText, recognizedText);

    // Save result
    const result = await SpeakingResult.create({
      userId,
      lessonId,
      audioUrl: audioUrl || '',
      audioPublicId: audioPublicId || '',
      score: scoringResult.score,
      accuracy: scoringResult.accuracy,
      passed: scoringResult.passed,
      wrongWords: scoringResult.wrongWords,
      suggestions: scoringResult.suggestions,
      highlightedText: scoringResult.highlightedText,
      referenceText,
      recognizedText: recognizedText || '',
      xpEarned: XP_CONFIG.PER_SPEAKING,
    });

    // Update user XP and skill progress
    const stars = calculateStars(scoringResult.score);
    await userService.addXP(userId, XP_CONFIG.PER_SPEAKING, io);
    await userService.addStars(userId, stars);
    await userService.updateSkillProgress(userId, 'speaking', scoringResult.score);

    if (scoringResult.passed && lessonId) {
      await userService.markLessonCompleted(userId, lessonId);
    }

    return {
      score: scoringResult.score,
      accuracy: scoringResult.accuracy,
      passed: scoringResult.passed,
      wrongWords: scoringResult.wrongWords,
      suggestions: scoringResult.suggestions,
      highlightedText: scoringResult.highlightedText,
      stars,
      xpEarned: XP_CONFIG.PER_SPEAKING,
    };
  }

  /**
   * STUB: Pronunciation scoring logic
   * This simulates AI-based pronunciation checking.
   * Replace with real AI service in production.
   */
  _stubPronunciationScoring(referenceText, recognizedText) {
    if (!recognizedText || !referenceText) {
      return {
        score: 0,
        accuracy: 0,
        passed: false,
        wrongWords: [],
        suggestions: ['Không nhận diện được giọng nói. Vui lòng thử lại.'],
        highlightedText: [],
      };
    }

    // Simple word-level comparison
    const refWords = referenceText.trim().split(/\s+/);
    const recWords = recognizedText.trim().split(/\s+/);

    const wrongWords = [];
    const highlightedText = [];
    let correctCount = 0;

    refWords.forEach((word, index) => {
      const recognized = recWords[index] || '';
      const isCorrect = word.toLowerCase() === recognized.toLowerCase();

      if (isCorrect) {
        correctCount++;
      } else {
        wrongWords.push({
          word,
          expected: word,
          actual: recognized || '(không nhận diện)',
        });
      }

      highlightedText.push({
        text: word,
        isCorrect,
      });
    });

    const accuracy = refWords.length > 0
      ? Math.round((correctCount / refWords.length) * 100)
      : 0;

    const score = accuracy;
    const passed = isPassed(score);

    const suggestions = wrongWords.length > 0
      ? [`Cần luyện thêm ${wrongWords.length} từ: ${wrongWords.map(w => w.word).join(', ')}`]
      : ['Phát âm tuyệt vời! 🎉'];

    return {
      score,
      accuracy,
      passed,
      wrongWords,
      suggestions,
      highlightedText,
    };
  }

  /**
   * Get speaking history for user
   */
  async getHistory(userId, query = {}) {
    const results = await SpeakingResult.find({ userId })
      .populate('lessonId', 'title type khmerText')
      .sort({ createdAt: -1 })
      .limit(parseInt(query.limit) || 20)
      .lean();

    return results;
  }
}

module.exports = new SpeakingService();
