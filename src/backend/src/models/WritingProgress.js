/**
 * ========================================
 * WritingProgress Model
 * ========================================
 *
 * Tracks each child's per-character writing journey:
 * how many attempts, best score, detailed error history.
 *
 * Separated from the main Progress model so that
 * the writing subsystem can evolve independently
 * and the history array can grow without bloating
 * the core progress document.
 *
 * @collection writingprogresses
 */

const mongoose = require('mongoose');

// ────────────────────────────────────────────────
// Sub-schema: Single analysis result snapshot
// ────────────────────────────────────────────────
const analysisSnapshotSchema = new mongoose.Schema(
  {
    /** Overall similarity score 0–100 */
    score: {
      type: Number,
      required: true,
      min: 0,
      max: 100,
    },

    /** Shape similarity sub-score (DTW-based) */
    shapeScore: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },

    /** Direction alignment sub-score */
    directionScore: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },

    /** Stroke-count match sub-score */
    strokeCountScore: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },

    /** Array of human-readable error strings (Vietnamese) */
    errors: {
      type: [String],
      default: [],
    },

    /**
     * Index of the stroke that triggered the primary
     * error, or -1 if no single stroke is at fault.
     */
    errorStrokeIndex: {
      type: Number,
      default: -1,
    },

    /** Vietnamese feedback sentence shown to child */
    feedback: {
      type: String,
      default: '',
    },

    /** When this attempt was analyzed */
    analyzedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false, suppressReservedKeysWarning: true }
);

// ────────────────────────────────────────────────
// Main schema: WritingProgress
// ────────────────────────────────────────────────
const writingProgressSchema = new mongoose.Schema(
  {
    // ════════════════════════════════════════════
    // References
    // ════════════════════════════════════════════
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'userId is required'],
      index: true,
    },

    /** The Khmer character this record tracks, e.g. "ក" */
    character: {
      type: String,
      required: [true, 'Character is required'],
      trim: true,
    },

    // ════════════════════════════════════════════
    // Aggregated progress
    // ════════════════════════════════════════════

    /** Highest similarity score ever achieved */
    bestScore: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },

    /** Stars earned (0-3) — derived from bestScore */
    stars: {
      type: Number,
      default: 0,
      min: 0,
      max: 3,
    },

    /** Total number of drawing attempts */
    attempts: {
      type: Number,
      default: 0,
      min: 0,
    },

    /** Whether the child has "mastered" this character (bestScore ≥ 70) */
    isCompleted: {
      type: Boolean,
      default: false,
    },

    // ════════════════════════════════════════════
    // History (capped to last 20 to prevent bloat)
    // ════════════════════════════════════════════
    history: {
      type: [analysisSnapshotSchema],
      default: [],
      validate: {
        validator: function (arr) {
          return arr.length <= 50;
        },
        message: 'History is capped at 50 entries',
      },
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ════════════════════════════════════════════════
// Indexes
// ════════════════════════════════════════════════
// Compound index: one progress doc per user per character
writingProgressSchema.index({ userId: 1, character: 1 }, { unique: true });
writingProgressSchema.index({ userId: 1, isCompleted: 1 });

// ════════════════════════════════════════════════
// Pre-save: derive stars from bestScore, cap history
// ════════════════════════════════════════════════
writingProgressSchema.pre('save', function (next) {
  // Stars derivation
  if (this.bestScore >= 90) this.stars = 3;
  else if (this.bestScore >= 70) this.stars = 2;
  else if (this.bestScore >= 50) this.stars = 1;
  else this.stars = 0;

  // Mark completed when score ≥ 70
  this.isCompleted = this.bestScore >= 70;

  // Cap history to last 50 entries (FIFO)
  if (this.history && this.history.length > 50) {
    this.history = this.history.slice(-50);
  }

  next();
});

// ════════════════════════════════════════════════
// Statics: convenience upsert
// ════════════════════════════════════════════════

/**
 * Record a new writing attempt for a user + character pair.
 * Creates the document if it does not exist, otherwise
 * pushes to history and updates bestScore atomically.
 *
 * @param {string} userId
 * @param {string} character
 * @param {Object} analysisResult  — output from aiStrokeAnalyzer
 * @returns {Promise<Document>}
 */
writingProgressSchema.statics.recordAttempt = async function (
  userId,
  character,
  analysisResult
) {
  const snapshot = {
    score: analysisResult.similarityScore || 0,
    shapeScore: analysisResult.shapeScore || 0,
    directionScore: analysisResult.directionScore || 0,
    strokeCountScore: analysisResult.strokeCountScore || 0,
    errors: analysisResult.errors || [],
    errorStrokeIndex: analysisResult.errorStrokeIndex ?? -1,
    feedback: analysisResult.feedback || '',
    analyzedAt: new Date(),
  };

  // Use findOneAndUpdate for atomic upsert
  const doc = await this.findOneAndUpdate(
    { userId, character },
    {
      $inc: { attempts: 1 },
      $push: {
        history: {
          $each: [snapshot],
          $slice: -50, // keep last 50
        },
      },
      $max: { bestScore: snapshot.score },
    },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );

  // Re-derive stars and isCompleted (they depend on bestScore)
  if (doc.bestScore >= 90) doc.stars = 3;
  else if (doc.bestScore >= 70) doc.stars = 2;
  else if (doc.bestScore >= 50) doc.stars = 1;
  else doc.stars = 0;
  doc.isCompleted = doc.bestScore >= 70;
  await doc.save();

  return doc;
};

const WritingProgress = mongoose.model(
  'WritingProgress',
  writingProgressSchema
);

module.exports = WritingProgress;
