/**
 * ========================================
 * Reading Result Model
 * ========================================
 */

const mongoose = require('mongoose');

const readingResultSchema = new mongoose.Schema(
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
    wordsRead: {
      type: Number,
      default: 0,
    },
    totalWords: {
      type: Number,
      default: 0,
    },
    timeSpent: {
      type: Number, // seconds
      default: 0,
    },
    passed: {
      type: Boolean,
      default: false,
    },
    xpEarned: {
      type: Number,
      default: 0,
    },
    linesCompleted: [{
      lineIndex: Number,
      isCorrect: Boolean,
    }],
  },
  {
    timestamps: true,
  }
);

readingResultSchema.index({ userId: 1, lessonId: 1, createdAt: -1 });

const ReadingResult = mongoose.model('ReadingResult', readingResultSchema);

module.exports = ReadingResult;
