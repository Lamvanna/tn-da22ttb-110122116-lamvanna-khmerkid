/**
 * ========================================
 * Listening Result Model
 * ========================================
 */

const mongoose = require('mongoose');

const listeningResultSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    lessonId: {
      type: String,
      ref: 'Lesson',
    },
    score: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },
    correctAnswers: {
      type: Number,
      default: 0,
    },
    totalQuestions: {
      type: Number,
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
    answers: [{
      questionIndex: Number,
      selectedAnswer: Number,
      correctAnswer: Number,
      isCorrect: Boolean,
    }],
  },
  {
    timestamps: true,
  }
);

listeningResultSchema.index({ userId: 1, lessonId: 1, createdAt: -1 });

const ListeningResult = mongoose.model('ListeningResult', listeningResultSchema);

module.exports = ListeningResult;
