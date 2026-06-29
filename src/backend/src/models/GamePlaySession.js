const mongoose = require('mongoose');

const gamePlaySessionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'userId là bắt buộc'],
    },
    lessonId: {
      type: String,
      required: [true, 'lessonId là bắt buộc'],
    },
    characterId: {
      type: String,
      required: [true, 'characterId là bắt buộc'],
    },
    totalQuestions: {
      type: Number,
      default: 20,
      required: true,
      validate: {
        validator: function (val) {
          return val === 20;
        },
        message: 'Tổng số câu hỏi phải là 20.',
      },
    },
    correctAnswers: {
      type: Number,
      required: [true, 'correctAnswers là bắt buộc'],
      min: [0, 'Số câu đúng không được nhỏ hơn 0'],
      max: [20, 'Số câu đúng không được lớn hơn 20'],
      validate: {
        validator: Number.isInteger,
        message: 'Số câu đúng phải là số nguyên',
      },
    },
    wrongAnswers: {
      type: Number,
      required: [true, 'wrongAnswers là bắt buộc'],
      min: [0, 'Số câu sai không được nhỏ hơn 0'],
      max: [20, 'Số câu sai không được lớn hơn 20'],
      validate: {
        validator: Number.isInteger,
        message: 'Số câu sai phải là số nguyên',
      },
    },
    stars: {
      type: Number,
      required: true,
      min: 0,
      max: 20,
    },
    bonusStars: {
      type: Number,
      required: true,
      min: 0,
      max: 20,
    },
    totalStars: {
      type: Number,
      required: true,
      min: 0,
      max: 40,
    },
    xp: {
      type: Number,
      required: true,
      min: 0,
      max: 200,
    },
    bonusXP: {
      type: Number,
      required: true,
      min: 0,
      max: 100,
    },
    totalXP: {
      type: Number,
      required: true,
      min: 0,
      max: 300,
    },
    perfectReward: {
      type: Boolean,
      default: false,
    },
    completedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// Ràng buộc correctAnswers + wrongAnswers phải bằng totalQuestions (20)
gamePlaySessionSchema.pre('validate', function (next) {
  if (typeof this.correctAnswers === 'number' && typeof this.wrongAnswers === 'number') {
    if (this.correctAnswers + this.wrongAnswers !== this.totalQuestions) {
      this.invalidate(
        'correctAnswers',
        `Tổng số câu đúng (${this.correctAnswers}) và câu sai (${this.wrongAnswers}) phải bằng tổng số câu hỏi (${this.totalQuestions}).`
      );
    }
  }
  next();
});

const GamePlaySession = mongoose.model('GamePlaySession', gamePlaySessionSchema);

module.exports = GamePlaySession;
