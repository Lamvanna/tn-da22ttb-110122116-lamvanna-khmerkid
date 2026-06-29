/**
 * ========================================
 * Writing Routes — REST API for Standard Characters
 * ========================================
 *
 * Provides endpoints for:
 *   - Fetching character metadata (stroke counts, difficulty)
 *   - Fetching full golden path data (for admin/debugging)
 *   - Fetching user writing progress
 *
 * These endpoints supplement the WebSocket-based real-time
 * analysis; they are used by the Flutter client to pre-load
 * character info for the anti-false recognition filter.
 *
 * @module routes/writingRoutes
 */

'use strict';

const router = require('express').Router();
const StandardCharacter = require('../models/StandardCharacter');
const WritingProgress = require('../models/WritingProgress');
const { globalErrorHandler, AppError } = require('../middlewares/errorHandler');

// ════════════════════════════════════════════════════════════════════
// Middleware: Optional auth (some endpoints are public)
// ════════════════════════════════════════════════════════════════════
let protect;
try {
  protect = require('../middlewares/auth').authenticate;
} catch (_) {
  // Fallback: no auth middleware available — pass through
  protect = (req, res, next) => next();
}

// ════════════════════════════════════════════════════════════════════
// PUBLIC ENDPOINTS
// ════════════════════════════════════════════════════════════════════

/**
 * GET /api/writing/characters
 *
 * List all active standard characters with metadata
 * (no full stroke data — lightweight for mobile).
 *
 * Query params:
 *   ?type=consonant|vowel|number|diacritical|combined
 *   ?difficulty=easy|medium|hard
 */
router.get('/characters', async (req, res, next) => {
  try {
    const filter = { isActive: true };

    if (req.query.type) {
      filter.type = req.query.type;
    }
    if (req.query.difficulty) {
      filter.difficulty = req.query.difficulty;
    }

    const characters = await StandardCharacter.find(
      filter,
      {
        character: 1,
        romanized: 1,
        type: 1,
        totalStrokes: 1,
        difficulty: 1,
        hint: 1,
      }
    )
      .sort({ difficulty: 1, character: 1 })
      .lean();

    res.status(200).json({
      success: true,
      count: characters.length,
      data: characters,
    });
  } catch (err) {
    next(new AppError(`Failed to fetch characters: ${err.message}`, 500));
  }
});

/**
 * GET /api/writing/characters/:character
 *
 * Fetch metadata for a single character.
 * The :character param is the Khmer character itself (URL-encoded).
 *
 * Example: GET /api/writing/characters/%E1%9E%80  (for "ក")
 */
router.get('/characters/:character', async (req, res, next) => {
  try {
    const char = decodeURIComponent(req.params.character).trim();
    if (!char) {
      return next(new AppError('Character parameter is required', 400));
    }

    const doc = await StandardCharacter.findOne(
      { character: char, isActive: true },
      { character: 1, romanized: 1, type: 1, totalStrokes: 1, difficulty: 1, hint: 1 }
    ).lean();

    if (!doc) {
      return next(
        new AppError(`Standard character "${char}" not found`, 404)
      );
    }

    res.status(200).json({
      success: true,
      data: doc,
    });
  } catch (err) {
    next(new AppError(`Failed to fetch character: ${err.message}`, 500));
  }
});

/**
 * GET /api/writing/characters/:character/strokes
 *
 * Fetch the full golden path stroke data for a character.
 * This is a heavier payload — used for admin tools or
 * debugging, not normally called from the mobile app.
 */
router.get('/characters/:character/strokes', async (req, res, next) => {
  try {
    const char = decodeURIComponent(req.params.character).trim();
    if (!char) {
      return next(new AppError('Character parameter is required', 400));
    }

    const doc = await StandardCharacter.findOne(
      { character: char, isActive: true }
    ).lean();

    if (!doc) {
      return next(
        new AppError(`Standard character "${char}" not found`, 404)
      );
    }

    res.status(200).json({
      success: true,
      data: {
        character: doc.character,
        totalStrokes: doc.totalStrokes,
        standardStrokes: doc.standardStrokes,
      },
    });
  } catch (err) {
    next(new AppError(`Failed to fetch strokes: ${err.message}`, 500));
  }
});

// ════════════════════════════════════════════════════════════════════
// PROTECTED ENDPOINTS (require auth)
// ════════════════════════════════════════════════════════════════════

/**
 * GET /api/writing/progress
 *
 * Fetch the authenticated user's writing progress for all characters.
 *
 * Query params:
 *   ?completed=true|false  — filter by completion status
 */
router.get('/progress', protect, async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId) {
      return next(new AppError('User ID not found in token', 401));
    }

    const filter = { userId };
    if (req.query.completed === 'true') {
      filter.isCompleted = true;
    } else if (req.query.completed === 'false') {
      filter.isCompleted = false;
    }

    const progress = await WritingProgress.find(filter)
      .sort({ character: 1 })
      .lean();

    res.status(200).json({
      success: true,
      count: progress.length,
      data: progress,
    });
  } catch (err) {
    next(new AppError(`Failed to fetch progress: ${err.message}`, 500));
  }
});

/**
 * GET /api/writing/progress/:character
 *
 * Fetch progress for a specific character.
 */
router.get('/progress/:character', protect, async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId) {
      return next(new AppError('User ID not found in token', 401));
    }

    const char = decodeURIComponent(req.params.character).trim();
    if (!char) {
      return next(new AppError('Character parameter is required', 400));
    }

    const progress = await WritingProgress.findOne({
      userId,
      character: char,
    }).lean();

    if (!progress) {
      // Return empty progress — not an error
      return res.status(200).json({
        success: true,
        data: {
          character: char,
          bestScore: 0,
          stars: 0,
          attempts: 0,
          isCompleted: false,
          history: [],
        },
      });
    }

    res.status(200).json({
      success: true,
      data: progress,
    });
  } catch (err) {
    next(new AppError(`Failed to fetch progress: ${err.message}`, 500));
  }
});

module.exports = router;
