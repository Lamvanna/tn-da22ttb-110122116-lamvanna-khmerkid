/**
 * ========================================
 * Lesson Model
 * ========================================
 * 
 * Khmer language lessons: consonants, vowels,
 * vocabulary, sentences with media support.
 */

const mongoose = require('mongoose');
const { LESSON_TYPES, DIFFICULTY } = require('../constants');

const lessonSchema = new mongoose.Schema(
  {
    // ========================================
    // Basic Info
    // ========================================
    title: {
      type: String,
      required: [true, 'Tiêu đề bài học là bắt buộc'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      enum: Object.values(LESSON_TYPES),
      required: [true, 'Loại bài học là bắt buộc'],
    },

    // ========================================
    // Content
    // ========================================
    khmerText: {
      type: String,
      required: [true, 'Chữ Khmer là bắt buộc'],
    },
    romanized: {
      type: String,
      default: '',
    },
    meaning: {
      type: String,
      default: '',
    },
    pronunciation: {
      type: String,
      default: '',
    },
    examples: [{
      khmer: String,
      romanized: String,
      meaning: String,
    }],

    // ========================================
    // Media (stored as Cloudinary URLs)
    // ========================================
    imageUrl: {
      type: String,
      default: '',
    },
    imagePublicId: {
      type: String,
      default: '',
    },
    audioUrl: {
      type: String,
      default: '',
    },
    audioPublicId: {
      type: String,
      default: '',
    },
    audioDuration: {
      type: Number,
      default: 0,
    },
    videoUrl: {
      type: String,
      default: '',
    },

    // ========================================
    // Lesson Settings
    // ========================================
    difficulty: {
      type: String,
      enum: Object.values(DIFFICULTY),
      default: DIFFICULTY.BEGINNER,
    },
    order: {
      type: Number,
      default: 0,
    },
    category: {
      type: String,
      default: '',
    },
    isActive: {
      type: Boolean,
      default: true,
    },

    // ========================================
    // For Writing Lessons
    // ========================================
    strokeOrder: [{
      step: Number,
      instruction: String,
      svgPath: String,
    }],

    // ========================================
    // For Reading Lessons
    // ========================================
    readingLines: [{
      khmer: String,
      romanized: String,
      meaning: String,
      audioUrl: String,
    }],

    // ========================================
    // For Listening Lessons
    // ========================================
    questions: [{
      question: String,
      audioUrl: String,
      options: [String],
      correctAnswer: Number,
      explanation: String,
    }],
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
lessonSchema.index({ type: 1, order: 1 });
lessonSchema.index({ difficulty: 1 });
lessonSchema.index({ isActive: 1 });
lessonSchema.index({ category: 1 });

const Lesson = mongoose.model('Lesson', lessonSchema);

module.exports = Lesson;
