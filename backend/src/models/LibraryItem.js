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
      enum: ['Sách', 'Audio', 'Video'],
      required: [true, 'Loại tài liệu là bắt buộc (Sách, Audio, Video)'],
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
    isActive: {
      type: Boolean,
      default: true,
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
