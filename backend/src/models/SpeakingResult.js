/**
 * ========================================
 * Speaking Result Model
 * ========================================
 */

const mongoose = require('mongoose');

const speakingResultSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    lessonId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lesson',
    },
    audioUrl: {
      type: String,
      default: '',
    },
    audioPublicId: {
      type: String,
      default: '',
    },
    score: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },
    accuracy: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },
    passed: {
      type: Boolean,
      default: false,
    },
    wrongWords: [{
      word: String,
      expected: String,
      actual: String,
    }],
    suggestions: [String],
    highlightedText: [{
      text: String,
      isCorrect: Boolean,
    }],
    xpEarned: {
      type: Number,
      default: 0,
    },
    referenceText: {
      type: String,
      default: '',
    },
    recognizedText: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

speakingResultSchema.index({ userId: 1, lessonId: 1, createdAt: -1 });

const SpeakingResult = mongoose.model('SpeakingResult', speakingResultSchema);

module.exports = SpeakingResult;
