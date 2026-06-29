/**
 * ========================================
 * Game Result Model
 * ========================================
 */

const mongoose = require('mongoose');
const { GAME_TYPES } = require('../constants');

const gameResultSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    gameType: {
      type: String,
      enum: Object.values(GAME_TYPES),
      required: true,
    },
    score: {
      type: Number,
      required: true,
      min: 0,
    },
    stars: {
      type: Number,
      default: 0,
      min: 0,
      max: 20,
    },
    level: {
      type: Number,
      default: 1,
    },
    time: {
      type: Number, // seconds
      default: 0,
    },
    correctAnswers: {
      type: Number,
      default: 0,
    },
    totalQuestions: {
      type: Number,
      default: 0,
    },
    xpEarned: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

gameResultSchema.index({ userId: 1, gameType: 1, createdAt: -1 });

const GameResult = mongoose.model('GameResult', gameResultSchema);

module.exports = GameResult;
