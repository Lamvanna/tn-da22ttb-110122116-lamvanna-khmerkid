/**
 * ========================================
 * GameQuestion Model
 * ========================================
 */

const mongoose = require('mongoose');

const gameQuestionSchema = new mongoose.Schema(
  {
    gameKey: {
      type: String,
      required: [true, 'gameKey là bắt buộc (ví dụ: letter_catch, word_search, sentence_builder, math_garden)'],
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Tiêu đề câu hỏi là bắt buộc'],
      trim: true,
    },
    prompt: {
      type: String,
      required: [true, 'Gợi ý/Câu hỏi (prompt) là bắt buộc'],
    },
    answer: {
      type: String,
      required: [true, 'Đáp án (answer) là bắt buộc'],
    },
    choices: {
      type: [String],
      default: [],
    },
    additionalData: {
      type: Map,
      of: mongoose.Schema.Types.Mixed,
      default: {},
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

const GameQuestion = mongoose.model('GameQuestion', gameQuestionSchema);

module.exports = GameQuestion;
