/**
 * ========================================
 * TestQuestion Model
 * ========================================
 */

const mongoose = require('mongoose');

const testQuestionSchema = new mongoose.Schema(
  {
    question: {
      type: String,
      required: [true, 'Câu hỏi là bắt buộc'],
      trim: true,
    },
    options: {
      type: [String],
      required: [true, 'Các phương án chọn lựa là bắt buộc'],
      validate: {
        validator: function (val) {
          return val && val.length >= 2;
        },
        message: 'Cần có ít nhất 2 lựa chọn',
      },
    },
    answer: {
      type: String,
      required: [true, 'Đáp án chính xác là bắt buộc'],
      trim: true,
    },
    testRange: {
      type: String,
      required: [true, 'Phạm vi bài kiểm tra là bắt buộc (ví dụ: 6-10, 13-17, 1-40)'],
      trim: true,
      index: true,
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    audioUrl: {
      type: String,
      default: '',
    },
    audioPublicId: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

const TestQuestion = mongoose.model('TestQuestion', testQuestionSchema);

module.exports = TestQuestion;
