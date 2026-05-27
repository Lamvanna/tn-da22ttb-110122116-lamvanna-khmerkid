/**
 * ========================================
 * Badge Model
 * ========================================
 */

const mongoose = require('mongoose');
const { BADGE_TYPES } = require('../constants');

const badgeSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Tên huy hiệu là bắt buộc'],
      trim: true,
      unique: true,
    },
    description: {
      type: String,
      required: [true, 'Mô tả huy hiệu là bắt buộc'],
    },
    iconUrl: {
      type: String,
      default: '',
    },
    iconPublicId: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      enum: Object.values(BADGE_TYPES),
      required: [true, 'Loại huy hiệu là bắt buộc'],
    },
    requirement: {
      type: {
        type: String,    // e.g., 'level_reach', 'streak_days', 'lessons_complete'
      },
      value: Number,     // e.g., 5 (level 5), 7 (7 days streak)
      description: String,
    },
    xpReward: {
      type: Number,
      default: 0,
    },
    starsReward: {
      type: Number,
      default: 0,
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

badgeSchema.index({ type: 1 });
badgeSchema.index({ order: 1 });

const Badge = mongoose.model('Badge', badgeSchema);

module.exports = Badge;
