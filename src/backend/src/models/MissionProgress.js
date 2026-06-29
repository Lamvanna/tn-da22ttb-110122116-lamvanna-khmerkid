/**
 * ========================================
 * Mission Progress Model
 * ========================================
 * 
 * Tracks individual user's mission progress.
 */

const mongoose = require('mongoose');

const missionProgressSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    missionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Mission',
      required: true,
    },
    progress: {
      type: Number,
      default: 0,
      min: 0,
    },
    isCompleted: {
      type: Boolean,
      default: false,
    },
    isClaimed: {
      type: Boolean,
      default: false,
    },
    claimedAt: {
      type: Date,
    },
    expiresAt: {
      type: Date,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for user + mission lookup
missionProgressSchema.index({ userId: 1, missionId: 1, expiresAt: 1 });
missionProgressSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index

const MissionProgress = mongoose.model('MissionProgress', missionProgressSchema);

module.exports = MissionProgress;
