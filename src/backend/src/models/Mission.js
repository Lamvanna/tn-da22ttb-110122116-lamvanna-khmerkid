/**
 * ========================================
 * Mission Model
 * ========================================
 * 
 * Daily/weekly missions with rewards.
 */

const mongoose = require('mongoose');
const { MISSION_TYPES, MISSION_ACTIONS } = require('../constants');

const missionSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Tiêu đề nhiệm vụ là bắt buộc'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      enum: Object.values(MISSION_TYPES),
      default: MISSION_TYPES.DAILY,
    },
    action: {
      type: String,
      enum: Object.values(MISSION_ACTIONS),
      required: true,
    },
    requirement: {
      type: Number,
      required: [true, 'Yêu cầu nhiệm vụ là bắt buộc'],
      min: 1,
    },
    reward: {
      xp: { type: Number, default: 0 },
      stars: { type: Number, default: 0 },
      badgeId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Badge',
      },
    },
    iconUrl: {
      type: String,
      default: '',
    },
    order: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

missionSchema.index({ type: 1, isActive: 1 });

const Mission = mongoose.model('Mission', missionSchema);

module.exports = Mission;
