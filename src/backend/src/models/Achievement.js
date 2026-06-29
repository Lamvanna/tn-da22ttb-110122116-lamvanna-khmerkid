/**
 * ========================================
 * Achievement Model
 * ========================================
 * 
 * Tracks user badge unlocks and progress.
 */

const mongoose = require('mongoose');

const achievementSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    badgeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Badge',
      required: true,
    },
    progress: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },
    isUnlocked: {
      type: Boolean,
      default: false,
    },
    unlockedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index: each user can have each badge only once
achievementSchema.index({ userId: 1, badgeId: 1 }, { unique: true });

const Achievement = mongoose.model('Achievement', achievementSchema);

module.exports = Achievement;
