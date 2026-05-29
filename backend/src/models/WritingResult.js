/**
 * ========================================
 * Writing Result Model
 * ========================================
 */

const mongoose = require('mongoose');

const writingResultSchema = new mongoose.Schema(
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
    imageUrl: {
      type: String,
      default: '',
    },
    imagePublicId: {
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
    strokeOrderCorrect: {
      type: Boolean,
      default: false,
    },
    passed: {
      type: Boolean,
      default: false,
    },
    shapeScore: {
      type: Number,
      default: 0,
    },
    strokeScore: {
      type: Number,
      default: 0,
    },
    directionScore: {
      type: Number,
      default: 0,
    },
    strokeCount: {
      type: Number,
      default: 0,
    },
    xpEarned: {
      type: Number,
      default: 0,
    },
    feedback: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

writingResultSchema.index({ userId: 1, lessonId: 1, createdAt: -1 });

const WritingResult = mongoose.model('WritingResult', writingResultSchema);

module.exports = WritingResult;
