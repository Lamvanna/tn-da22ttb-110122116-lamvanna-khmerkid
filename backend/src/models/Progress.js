/**
 * ========================================
 * Progress Model
 * ========================================
 * 
 * Lưu toàn bộ tiến độ học của user.
 * Source of truth cho offline-first sync.
 */

const mongoose = require('mongoose');

const progressSchema = new mongoose.Schema(
  {
    // ========================================
    // User Reference
    // ========================================
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    // ========================================
    // Completed Lessons
    // ========================================
    completedLessons: [{
      lessonId: {
        type: String,
        required: true,
      },
      lessonType: {
        type: String,
        default: '',
      },
      lessonOrder: {
        type: Number,
        default: 0,
      },
      stars: {
        type: Number,
        default: 0,
        min: 0,
        max: 5,
      },
      isCompleted: {
        type: Boolean,
        default: true,
      },
      completedAt: {
        type: Date,
        default: Date.now,
      },
    }],

    // ========================================
    // Unlocked Lessons
    // ========================================
    unlockedLessons: [{
      type: String,
    }],

    // ========================================
    // Game Results
    // ========================================
    gameResults: [{
      gameType: String,
      score: { type: Number, default: 0 },
      timeSeconds: { type: Number, default: 0 },
      correctAnswers: { type: Number, default: 0 },
      totalQuestions: { type: Number, default: 0 },
      playedAt: { type: Date, default: Date.now },
    }],

    // ========================================
    // Achievements
    // ========================================
    achievements: [{
      type: String,
    }],

    // ========================================
    // Sync Metadata
    // ========================================
    lastSyncAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ========================================
// Indexes
// ========================================
progressSchema.index({ userId: 1 }, { unique: true });
progressSchema.index({ 'completedLessons.lessonId': 1 });

// ========================================
// Virtuals
// ========================================
progressSchema.virtual('totalCompleted').get(function () {
  return this.completedLessons ? this.completedLessons.filter(l => l.isCompleted).length : 0;
});

const Progress = mongoose.model('Progress', progressSchema);

module.exports = Progress;
