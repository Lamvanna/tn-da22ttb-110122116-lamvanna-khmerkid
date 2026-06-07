/**
 * ========================================
 * StandardCharacter Model (Golden Path)
 * ========================================
 *
 * Stores the canonical ("golden path") stroke data
 * for each Khmer character. This is the ground truth
 * against which children's handwriting is compared
 * by the AI Stroke Analyzer (Tier 2).
 *
 * Data structure rationale:
 *   A character = array of strokes
 *   A stroke    = array of points
 *   A point     = { x, y, t }
 *
 * Coordinates are normalized to a 100×100 virtual
 * canvas so device resolution is irrelevant.
 *
 * @collection standardcharacters
 */

const mongoose = require('mongoose');

// ────────────────────────────────────────────────
// Sub-schema: A single sampled point on a stroke
// ────────────────────────────────────────────────
const pointSchema = new mongoose.Schema(
  {
    /** Horizontal coordinate (0–100, normalized) */
    x: {
      type: Number,
      required: [true, 'Point must have an x coordinate'],
      min: 0,
      max: 100,
    },

    /** Vertical coordinate (0–100, normalized) */
    y: {
      type: Number,
      required: [true, 'Point must have a y coordinate'],
      min: 0,
      max: 100,
    },

    /**
     * Timestamp in milliseconds since the stroke started.
     * Used by the Directional Analysis algorithm to infer
     * the writing direction (top→bottom vs bottom→top).
     */
    t: {
      type: Number,
      required: [true, 'Point must have a timestamp'],
      min: 0,
    },
  },
  { _id: false } // points don't need their own ObjectId
);

// ────────────────────────────────────────────────
// Main schema: StandardCharacter
// ────────────────────────────────────────────────
const standardCharacterSchema = new mongoose.Schema(
  {
    // ════════════════════════════════════════════
    // Identity
    // ════════════════════════════════════════════

    /** The Khmer character this document represents, e.g. "ក" */
    character: {
      type: String,
      required: [true, 'Character is required'],
      unique: true,
      trim: true,
    },

    /**
     * Human-readable romanized pronunciation.
     * Helpful for admin/seeder readability; not used in the algorithm.
     */
    romanized: {
      type: String,
      default: '',
      trim: true,
    },

    /**
     * Character category.
     * consonant | vowel | number | diacritical | combined
     */
    type: {
      type: String,
      enum: ['consonant', 'vowel', 'number', 'diacritical', 'combined'],
      default: 'consonant',
    },

    // ════════════════════════════════════════════
    // Stroke Data (Golden Path)
    // ════════════════════════════════════════════

    /**
     * The canonical strokes for this character.
     * Outer array = strokes (pen-down → pen-up).
     * Inner array = ordered sequence of points.
     *
     * Example for "ក" (2 strokes):
     * [
     *   [ {x:20,y:10,t:0}, {x:25,y:30,t:50}, ... ],  // stroke 1
     *   [ {x:50,y:10,t:0}, {x:50,y:80,t:120}, ... ],  // stroke 2
     * ]
     */
    standardStrokes: {
      type: [[pointSchema]],
      required: [true, 'Standard strokes are required'],
      validate: {
        validator: function (strokes) {
          // At least 1 stroke, each stroke has ≥ 2 points
          if (!strokes || strokes.length === 0) return false;
          return strokes.every((s) => Array.isArray(s) && s.length >= 2);
        },
        message:
          'standardStrokes must contain at least 1 stroke, each with ≥ 2 points',
      },
    },

    /** Total number of strokes (pre-computed for quick filter) */
    totalStrokes: {
      type: Number,
      required: [true, 'Total stroke count is required'],
      min: 1,
      max: 20,
    },

    // ════════════════════════════════════════════
    // Metadata
    // ════════════════════════════════════════════

    /** Difficulty tier for adaptive learning */
    difficulty: {
      type: String,
      enum: ['easy', 'medium', 'hard'],
      default: 'easy',
    },

    /** Short hint displayed to the child (Vietnamese) */
    hint: {
      type: String,
      default: '',
    },

    /**
     * Whether this record is actively used.
     * Allows soft-deleting obsolete golden paths.
     */
    isActive: {
      type: Boolean,
      default: true,
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
// character index is created via `unique: true` in field definition
standardCharacterSchema.index({ type: 1, difficulty: 1 });
standardCharacterSchema.index({ isActive: 1 });

// ════════════════════════════════════════════════
// Virtuals
// ════════════════════════════════════════════════
standardCharacterSchema.virtual('totalPoints').get(function () {
  if (!this.standardStrokes) return 0;
  return this.standardStrokes.reduce((sum, s) => sum + s.length, 0);
});

// ════════════════════════════════════════════════
// Pre-save: auto-calculate totalStrokes
// ════════════════════════════════════════════════
standardCharacterSchema.pre('save', function (next) {
  if (this.standardStrokes) {
    this.totalStrokes = this.standardStrokes.length;
  }
  next();
});

const StandardCharacter = mongoose.model(
  'StandardCharacter',
  standardCharacterSchema
);

module.exports = StandardCharacter;
