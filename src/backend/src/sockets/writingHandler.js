/**
 * ═══════════════════════════════════════════════════════════════════════
 * Writing Socket Handler — Real-time Stroke Analysis via WebSocket
 * ═══════════════════════════════════════════════════════════════════════
 *
 * Handles the `analyze_strokes` event from Flutter clients.
 * Pipeline:
 *   1. Receive { targetCharacter, userStrokeData } from client
 *   2. Query StandardCharacter collection for golden path
 *   3. Run AI Stroke Analyzer (DTW + Directional)
 *   4. Persist result in WritingProgress
 *   5. Emit analysis result back to client
 *
 * @module sockets/writingHandler
 */

'use strict';

const StandardCharacter = require('../models/StandardCharacter');
const WritingProgress = require('../models/WritingProgress');
const User = require('../models/User');
const { analyzeStrokes } = require('../services/aiStrokeAnalyzer');
const { analyzeVowelStrokes } = require('../services/aiVowelStrokeAnalyzer');
const { analyzeCompoundStrokes } = require('../services/aiCompoundStrokeAnalyzer');
const missionService = require('../services/missionService');

// ═══════════════════════════════════════════════════════════════════════
// Validation Helpers
// ═══════════════════════════════════════════════════════════════════════

/**
 * Validate incoming stroke data payload.
 *
 * Expected shape:
 * {
 *   targetCharacter: "ក",                        // required string
 *   userStrokeData: [                             // required array of strokes
 *     [ { x: 10.5, y: 20.3, t: 0 }, ... ],       // stroke 0
 *     [ { x: 50.0, y: 10.0, t: 200 }, ... ],     // stroke 1
 *   ]
 * }
 *
 * @param {Object} data
 * @returns {{ valid: boolean, error?: string }}
 */
function validatePayload(data) {
  if (!data || typeof data !== 'object') {
    return { valid: false, error: 'Payload must be a non-null object' };
  }

  const { targetCharacter } = data;

  // ── targetCharacter ─────────────────────────────────────────────
  if (!targetCharacter || typeof targetCharacter !== 'string') {
    return { valid: false, error: 'targetCharacter is required and must be a string' };
  }

  if (targetCharacter.trim().length === 0) {
    return { valid: false, error: 'targetCharacter must not be empty' };
  }

  // Filter out accidental taps / noise strokes with less than 2 points
  if (Array.isArray(data.userStrokeData)) {
    data.userStrokeData = data.userStrokeData.filter(
      (stroke) => Array.isArray(stroke) && stroke.length >= 2
    );
  }

  const { userStrokeData } = data;

  // ── userStrokeData ──────────────────────────────────────────────
  if (!Array.isArray(userStrokeData) || userStrokeData.length === 0) {
    return { valid: false, error: 'userStrokeData must be a non-empty array of strokes' };
  }

  for (let si = 0; si < userStrokeData.length; si++) {
    const stroke = userStrokeData[si];
    if (!Array.isArray(stroke) || stroke.length < 2) {
      return {
        valid: false,
        error: `Stroke ${si} must be an array with at least 2 points`,
      };
    }

    for (let pi = 0; pi < stroke.length; pi++) {
      const pt = stroke[pi];
      if (!pt || typeof pt !== 'object') {
        return { valid: false, error: `Stroke ${si}, point ${pi} is not a valid object` };
      }
      if (typeof pt.x !== 'number' || typeof pt.y !== 'number') {
        return {
          valid: false,
          error: `Stroke ${si}, point ${pi}: x and y must be numbers`,
        };
      }
      if (pt.t != null && typeof pt.t !== 'number') {
        return {
          valid: false,
          error: `Stroke ${si}, point ${pi}: t must be a number if provided`,
        };
      }
    }
  }

  return { valid: true };
}

// ═══════════════════════════════════════════════════════════════════════
// Stars Derivation
// ═══════════════════════════════════════════════════════════════════════

/**
 * Convert a similarity score (0–100) to child-friendly stars (0–3).
 * @param {number} score
 * @returns {number}
 */
function scoreToStars(score) {
  if (score >= 90) return 3;
  if (score >= 70) return 2;
  if (score >= 50) return 1;
  return 0;
}

// ═══════════════════════════════════════════════════════════════════════
// Handler Registration
// ═══════════════════════════════════════════════════════════════════════

/**
 * Register writing-related socket event handlers on a connected socket.
 *
 * @param {import('socket.io').Socket} socket — authenticated socket instance
 * @param {import('socket.io').Server} io — server instance (for broadcasting if needed)
 */
function registerWritingHandler(socket, io) {
  const userId = socket.user?.id;

  /**
   * ─── EVENT: analyze_strokes ─────────────────────────────────────
   *
   * Client emits this immediately when the child lifts their pen
   * on the final stroke. The server runs the full geometric analysis
   * pipeline and responds with detailed correction feedback.
   */
  socket.on('analyze_strokes', async (data, ackCallback) => {
    const requestId = `${socket.id}-${Date.now()}`;
    console.log(`📝 [WritingHandler] analyze_strokes received (request: ${requestId})`);

    try {
      // ── Step 1: Validate ──────────────────────────────────────
      const validation = validatePayload(data);
      if (!validation.valid) {
        const errorResponse = {
          success: false,
          similarityScore: 0,
          feedback: 'Dữ liệu nét vẽ không hợp lệ. Hãy thử lại nhé! ✏️',
          errorStrokeIndex: -1,
          errors: [validation.error],
        };
        console.warn(`⚠️ [WritingHandler] Validation failed: ${validation.error}`);
        return emitResult(socket, ackCallback, errorResponse);
      }

      const { targetCharacter, userStrokeData } = data;

      // Strip ◌ (U+25CC dotted circle) prefix — vowel display characters
      // include it but DB stores vowel marks without the prefix
      const cleanCharacter = targetCharacter.trim().replace(/\u25CC/g, '');

      // ── Step 2: Fetch golden path from database ───────────────
      const standardDoc = await StandardCharacter.findOne({
        character: cleanCharacter,
        isActive: true,
      }).lean();

      // ── Step 3: Sanitize and ensure timestamps ─────────────────
      const sanitizedUserStrokes = userStrokeData.map((stroke) =>
        stroke.map((pt, idx) => ({
          x: Number(pt.x) || 0,
          y: Number(pt.y) || 0,
          t: pt.t != null ? Number(pt.t) : idx * 16, // ~60fps fallback
        }))
      );

      // ── Step 4: Run AI analysis ───────────────────────────────
      let analysisResult;

      if (!standardDoc) {
        console.log(
          `ℹ️ [WritingHandler] No StandardCharacter for "${targetCharacter}" — routing to compound analyzer`
        );

        // Find expected strokes for each individual character component
        const componentStrokeCounts = [];
        const componentStandardStrokes = [];
        const parts = [...cleanCharacter].filter(c => c !== '\u17D2');
        for (const charPart of parts) {
          const doc = await StandardCharacter.findOne({
            character: charPart,
            isActive: true
          }).lean();
          if (doc && doc.standardStrokes) {
            componentStrokeCounts.push(doc.standardStrokes.length);
            componentStandardStrokes.push(...doc.standardStrokes);
          } else {
            // Fallback for diacritics / unrecognized parts:
            // Diacritics usually take 1 stroke, others 2.
            const code = charPart.charCodeAt(0);
            const isDiacritic = code >= 0x17C6 && code <= 0x17D3;
            componentStrokeCounts.push(isDiacritic ? 1 : 2);
          }
        }

        analysisResult = analyzeCompoundStrokes({
          userStrokes: sanitizedUserStrokes,
          character: targetCharacter,
          componentStrokeCounts,
          componentStandardStrokes,
        });
      } else {
        if (standardDoc.type === 'vowel') {
          analysisResult = analyzeVowelStrokes({
            userStrokes: sanitizedUserStrokes,
            standardStrokes: standardDoc.standardStrokes,
            character: targetCharacter,
          });
        } else {
          analysisResult = analyzeStrokes({
            userStrokes: sanitizedUserStrokes,
            standardStrokes: standardDoc.standardStrokes,
            character: targetCharacter,
          });
        }
      }

      // ── Step 5: Derive gamification rewards ───────────────────
      const stars = scoreToStars(analysisResult.similarityScore);
      const passed = analysisResult.success &&
                     analysisResult.similarityScore >= 65;
      const xpEarned = passed ? stars * 5 : 0;

      // ── Step 6: Persist to WritingProgress ────────────────────
      if (userId) {
        try {
          await WritingProgress.recordAttempt(userId, targetCharacter, analysisResult);
          // Tăng counter luyện viết (cho badge)
          await User.findByIdAndUpdate(userId, {
            $inc: { 'learningProgress.writingPracticeCount': 1 }
          });
          // Update mission progress for writing practice
          await missionService.updateProgress(userId, 'write_lesson');
          console.log(
            `✅ [WritingHandler] Progress saved for user ${userId}, ` +
            `char "${targetCharacter}", score: ${analysisResult.similarityScore}`
          );
        } catch (dbErr) {
          console.error(
            `❌ [WritingHandler] Failed to save progress: ${dbErr.message}`
          );
        }
      }

      // ── Step 7: Build response ────────────────────────────────
      const response = {
        success: analysisResult.success,
        similarityScore: analysisResult.similarityScore,
        shapeScore: analysisResult.shapeScore,
        directionScore: analysisResult.directionScore,
        strokeCountScore: analysisResult.strokeCountScore,
        feedback: analysisResult.feedback,
        errorStrokeIndex: analysisResult.errorStrokeIndex,
        errors: analysisResult.errors,
        stars,
        passed,
        xpEarned,
        details: analysisResult.details,
      };

      console.log(
        `📊 [WritingHandler] Analysis complete: ` +
        `score=${response.similarityScore}, stars=${stars}, passed=${passed}`
      );

      return emitResult(socket, ackCallback, response);

    } catch (err) {
      console.error(`❌ [WritingHandler] Unexpected error: ${err.message}`, err.stack);
      const errorResponse = {
        success: false,
        similarityScore: 0,
        feedback: 'Đã xảy ra lỗi khi phân tích nét vẽ. Hãy thử lại nhé! 🔄',
        errorStrokeIndex: -1,
        errors: [err.message],
      };
      return emitResult(socket, ackCallback, errorResponse);
    }
  });

  /**
   * ─── EVENT: get_character_info ──────────────────────────────────
   *
   * Lightweight query to fetch metadata about a character
   * (stroke count, difficulty) without the full golden path data.
   * Used by the Flutter anti-false recognition filter.
   */
  socket.on('get_character_info', async (data, ackCallback) => {
    try {
      const character = data?.character?.trim()?.replace(/\u25CC/g, '');
      if (!character) {
        return emitResult(socket, ackCallback, {
          success: false,
          error: 'character is required',
        }, 'character_info_result');
      }

      const doc = await StandardCharacter.findOne(
        { character, isActive: true },
        { character: 1, totalStrokes: 1, difficulty: 1, hint: 1, type: 1 }
      ).lean();

      if (!doc) {
        return emitResult(socket, ackCallback, {
          success: false,
          error: `No standard data for "${character}"`,
        }, 'character_info_result');
      }

      return emitResult(socket, ackCallback, {
        success: true,
        character: doc.character,
        totalStrokes: doc.totalStrokes,
        difficulty: doc.difficulty,
        hint: doc.hint,
        type: doc.type,
      }, 'character_info_result');

    } catch (err) {
      console.error(`❌ [WritingHandler] get_character_info error: ${err.message}`);
      return emitResult(socket, ackCallback, {
        success: false,
        error: err.message,
      }, 'character_info_result');
    }
  });

  console.log(`📝 [WritingHandler] Registered for user ${userId || 'anonymous'}`);
}

// ═══════════════════════════════════════════════════════════════════════
// Emit Helper
// ═══════════════════════════════════════════════════════════════════════

/**
 * Emit result either via Socket.IO acknowledgement callback (if the
 * client used `socket.emitWithAck`) or via a named event.
 *
 * @param {import('socket.io').Socket} socket
 * @param {Function|undefined} ackCallback
 * @param {Object} payload
 * @param {string} [eventName='stroke_analysis_result']
 */
function emitResult(socket, ackCallback, payload, eventName = 'stroke_analysis_result') {
  if (typeof ackCallback === 'function') {
    ackCallback(payload);
  } else {
    socket.emit(eventName, payload);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Exports
// ═══════════════════════════════════════════════════════════════════════

module.exports = { registerWritingHandler };
