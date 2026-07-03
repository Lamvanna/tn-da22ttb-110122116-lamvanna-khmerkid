/**
 * ========================================
 * LibraryItem Model
 * ========================================
 */

const mongoose = require('mongoose');

const libraryItemSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Tiêu đề tài liệu là bắt buộc'],
      trim: true,
    },
    type: {
      type: String,
      enum: ['Sách', 'Truyện', 'Audio', 'Video'],
      required: [true, 'Loại tài liệu là bắt buộc (Sách, Truyện, Audio, Video)'],
    },
    description: {
      type: String,
      default: '',
    },
    image: {
      type: String,
      default: '',
    },
    contentUrl: {
      type: String,
      default: '',
    },
    views: {
      type: Number,
      default: 0,
    },
    rating: {
      type: Number,
      default: 5.0,
      min: 0,
      max: 5,
    },
    duration: {
      type: String,
      default: '',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    pages: [
      {
        textKhmer: {
          type: String,
          default: '',
        },
        textVietnamese: {
          type: String,
          default: '',
        },
        illustration: {
          type: String,
          default: '',
        },
        highlights: {
          type: [String],
          default: [],
        },
      },
    ],
    lyrics: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

libraryItemSchema.index({ type: 1 });
libraryItemSchema.index({ isActive: 1 });

const LibraryItem = mongoose.model('LibraryItem', libraryItemSchema);

module.exports = LibraryItem;
