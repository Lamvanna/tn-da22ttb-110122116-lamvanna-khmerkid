/**
 * ========================================
 * TTS Cache Model
 * ========================================
 */

const mongoose = require('mongoose');

const ttsCacheSchema = new mongoose.Schema(
  {
    text: {
      type: String,
      required: true,
    },
    locale: {
      type: String,
      required: true,
      default: 'km',
    },
    audioBase64: {
      type: String,
      required: true,
    },
    createdAt: {
      type: Date,
      default: Date.now,
      expires: 30 * 24 * 60 * 60, // 30 days
    },
  }
);

// Create compound index for unique lookups and performance
ttsCacheSchema.index({ text: 1, locale: 1 }, { unique: true });

const TtsCache = mongoose.model('TtsCache', ttsCacheSchema);

module.exports = TtsCache;
