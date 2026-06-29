/**
 * ═══════════════════════════════════════════════════════════════════════
 * AI Stroke Analyzer — Core Geometric Handwriting Comparison Engine
 * ═══════════════════════════════════════════════════════════════════════
 *
 * This module contains the mathematical backbone of Tier 2 recognition.
 * Given a child's raw stroke data and a "golden path" from the database,
 * it produces:
 *   1. A numeric similarity score (0–100)
 *   2. Per-stroke directional correctness
 *   3. A human-readable Vietnamese feedback sentence
 *
 * ─── Algorithm Pipeline ───────────────────────────────────────────────
 *
 *   Raw User Strokes
 *         │
 *         ▼
 *   ┌─────────────┐
 *   │  Normalize   │  Translate centroid → origin, scale to [0,100]²
 *   └──────┬──────┘
 *          │
 *          ▼
 *   ┌─────────────┐
 *   │  Resample    │  Equidistant N=32 points per stroke
 *   └──────┬──────┘
 *          │
 *          ▼
 *   ┌─────────────────────────────────────────────────┐
 *   │  Analysis Stages (run in parallel per stroke)   │
 *   │                                                 │
 *   │  1. Stroke Count Match                          │
 *   │  2. Directional Vector Alignment (cosine sim)   │
 *   │  3. Shape Similarity via DTW                    │
 *   └──────┬──────────────────────────────────────────┘
 *          │
 *          ▼
 *   ┌─────────────┐
 *   │  Aggregate   │  Weighted composite → score + feedback
 *   └─────────────┘
 *
 * ─── Why DTW? ─────────────────────────────────────────────────────────
 *
 * Dynamic Time Warping is chosen over simpler metrics (Euclidean, Hausdorff)
 * because children write at wildly varying speeds and may pause mid-stroke.
 * DTW allows elastic time alignment — two strokes with similar shapes but
 * different temporal profiles still match well.
 *
 * ─── Why Cosine Direction Vectors? ────────────────────────────────────
 *
 * Simply comparing point positions cannot distinguish a stroke drawn
 * top-to-bottom from one drawn bottom-to-top. By computing the unit
 * direction vector between consecutive points and comparing via cosine
 * similarity, we reliably detect reversed strokes — a common mistake
 * when children learn to write.
 *
 * @module services/aiStrokeAnalyzer
 * @author KhmerKid AI Team
 */

'use strict';

// ═══════════════════════════════════════════════════════════════════════
// Constants
// ═══════════════════════════════════════════════════════════════════════

/** Number of equidistant sample points per stroke after resampling */
const RESAMPLE_COUNT = 32;

/** Normalized canvas bounds after scaling */
const NORM_SIZE = 100;

/**
 * Scoring weights (must sum to 1.0):
 *   - Shape similarity (DTW)       : 50%
 *   - Directional alignment        : 30%
 *   - Stroke count accuracy        : 20%
 */
const WEIGHTS = Object.freeze({
  shape: 0.50,
  direction: 0.30,
  strokeCount: 0.20,
});

/**
 * If the cosine similarity between a user's stroke direction vector
 * and the standard's is below this threshold, flag it as "reversed".
 */
const DIRECTION_REVERSE_THRESHOLD = -0.3;

/**
 * Maximum DTW distance (per point pair) that maps to 0% similarity.
 * Distances beyond this are clamped.
 * Set to 120 to be more tolerant of shape variations in complex curved characters.
 */
const DTW_MAX_DISTANCE = 120;

// ═══════════════════════════════════════════════════════════════════════
// Geometry Utilities
// ═══════════════════════════════════════════════════════════════════════

/**
 * Euclidean distance between two 2D points.
 * @param {{x:number,y:number}} a
 * @param {{x:number,y:number}} b
 * @returns {number}
 */
function dist(a, b) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return Math.sqrt(dx * dx + dy * dy);
}

/**
 * Compute the total path length of a stroke (sum of consecutive distances).
 * @param {Array<{x:number,y:number}>} points
 * @returns {number}
 */
function pathLength(points) {
  let total = 0;
  for (let i = 1; i < points.length; i++) {
    total += dist(points[i - 1], points[i]);
  }
  return total;
}

/**
 * Compute the centroid (geometric center) of a set of points.
 * @param {Array<{x:number,y:number}>} points
 * @returns {{x:number, y:number}}
 */
function centroid(points) {
  if (points.length === 0) return { x: 0, y: 0 };
  let sx = 0, sy = 0;
  for (const p of points) {
    sx += p.x;
    sy += p.y;
  }
  return { x: sx / points.length, y: sy / points.length };
}

/**
 * Axis-aligned bounding box of a point set.
 * @param {Array<{x:number,y:number}>} points
 * @returns {{minX:number, minY:number, maxX:number, maxY:number, width:number, height:number}}
 */
function boundingBox(points) {
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  for (const p of points) {
    if (p.x < minX) minX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.x > maxX) maxX = p.x;
    if (p.y > maxY) maxY = p.y;
  }
  return {
    minX, minY, maxX, maxY,
    width: maxX - minX,
    height: maxY - minY,
  };
}

// ═══════════════════════════════════════════════════════════════════════
// Preprocessing
// ═══════════════════════════════════════════════════════════════════════

/**
 * Resample a stroke to exactly N equidistant points along its path.
 *
 * Algorithm:
 *   1. Compute total path length L.
 *   2. Step size = L / (N-1).
 *   3. Walk along the path, emitting a point every `step` units.
 *
 * This ensures that both fast and slow handwriting produce the same
 * number of comparison points, which is required by DTW.
 *
 * @param {Array<{x:number,y:number,t?:number}>} points  Raw points
 * @param {number} [n=RESAMPLE_COUNT]  Target count
 * @returns {Array<{x:number,y:number,t:number}>}
 */
function resampleStroke(points, n = RESAMPLE_COUNT) {
  if (points.length === 0) return [];
  if (points.length === 1) {
    // Degenerate: a dot — replicate it n times
    return Array.from({ length: n }, () => ({ ...points[0] }));
  }

  const totalLen = pathLength(points);
  if (totalLen === 0) {
    // All points overlap — treat as a dot
    return Array.from({ length: n }, () => ({ ...points[0] }));
  }

  // Clone points to avoid mutating the original input array
  const pts = points.map((p) => ({ ...p }));

  const interval = totalLen / (n - 1);
  const resampled = [{ ...pts[0] }];
  let accum = 0;

  let i = 1;
  while (i < pts.length && resampled.length < n) {
    const d = dist(pts[i - 1], pts[i]);
    if (d === 0) {
      i++;
      continue;
    }

    if (accum + d >= interval) {
      const ratio = (interval - accum) / d;
      const nx = pts[i - 1].x + ratio * (pts[i].x - pts[i - 1].x);
      const ny = pts[i - 1].y + ratio * (pts[i].y - pts[i - 1].y);
      // Interpolate timestamp too
      const nt = pts[i - 1].t != null && pts[i].t != null
        ? pts[i - 1].t + ratio * (pts[i].t - pts[i - 1].t)
        : 0;

      const newPt = { x: nx, y: ny, t: Math.round(nt) };
      resampled.push(newPt);

      // The new point becomes the starting point of the remaining segment
      pts[i - 1] = newPt;
      accum = 0;
      // Do not increment i, as we need to continue checking the remaining segment
    } else {
      accum += d;
      i++;
    }
  }

  // Edge case: floating-point drift may leave us 1 point short
  while (resampled.length < n) {
    resampled.push({ ...pts[pts.length - 1] });
  }

  return resampled.slice(0, n);
}


/**
 * Normalize all strokes so that the combined bounding box fits
 * within [0, NORM_SIZE] × [0, NORM_SIZE], preserving aspect ratio.
 *
 * Steps:
 *   1. Flatten all points to find the global bounding box.
 *   2. Translate so minX=0, minY=0.
 *   3. Scale the larger dimension to NORM_SIZE; scale the
 *      smaller dimension by the same factor to preserve aspect ratio.
 *
 * @param {Array<Array<{x:number,y:number,t?:number}>>} strokes
 * @returns {Array<Array<{x:number,y:number,t:number}>>}
 */
function normalizeStrokes(strokes) {
  // Flatten all points to compute global bounding box
  const allPoints = strokes.flat();
  if (allPoints.length === 0) return strokes;

  const bb = boundingBox(allPoints);
  const maxDim = Math.max(bb.width, bb.height);

  if (maxDim === 0) {
    // All points are identical — center them
    return strokes.map((s) =>
      s.map((p) => ({ x: NORM_SIZE / 2, y: NORM_SIZE / 2, t: p.t || 0 }))
    );
  }

  const scale = NORM_SIZE / maxDim;

  // Offset to center the smaller dimension
  const scaledW = bb.width * scale;
  const scaledH = bb.height * scale;
  const offsetX = (NORM_SIZE - scaledW) / 2;
  const offsetY = (NORM_SIZE - scaledH) / 2;

  return strokes.map((stroke) =>
    stroke.map((p) => ({
      x: (p.x - bb.minX) * scale + offsetX,
      y: (p.y - bb.minY) * scale + offsetY,
      t: p.t || 0,
    }))
  );
}

// ═══════════════════════════════════════════════════════════════════════
// Dynamic Time Warping (DTW)
// ═══════════════════════════════════════════════════════════════════════

/**
 * Compute DTW distance between two sequences of 2D points.
 *
 * Standard DP formulation:
 *   D[i][j] = dist(s1[i], s2[j]) + min(D[i-1][j], D[i][j-1], D[i-1][j-1])
 *
 * Returns the averaged DTW distance (total / path length) so the
 * result is comparable across different sequence lengths.
 *
 * Time complexity: O(n × m)   Space: O(n × m)
 * With n, m ≤ 32 this is trivial (≤ 1024 cells).
 *
 * @param {Array<{x:number,y:number}>} s1
 * @param {Array<{x:number,y:number}>} s2
 * @returns {number} Average DTW distance per step
 */
function dtwDistance(s1, s2) {
  const n = s1.length;
  const m = s2.length;
  if (n === 0 || m === 0) return Infinity;

  // Initialize DP matrix with Infinity
  const D = Array.from({ length: n + 1 }, () =>
    new Float64Array(m + 1).fill(Infinity)
  );
  D[0][0] = 0;

  for (let i = 1; i <= n; i++) {
    for (let j = 1; j <= m; j++) {
      const cost = dist(s1[i - 1], s2[j - 1]);
      D[i][j] = cost + Math.min(D[i - 1][j], D[i][j - 1], D[i - 1][j - 1]);
    }
  }

  // Backtrack to find optimal warping path length
  let pathLen = 0;
  let i = n, j = m;
  while (i > 0 || j > 0) {
    pathLen++;
    if (i === 0) { j--; continue; }
    if (j === 0) { i--; continue; }
    const options = [
      { cost: D[i - 1][j - 1], ni: i - 1, nj: j - 1 },
      { cost: D[i - 1][j],     ni: i - 1, nj: j },
      { cost: D[i][j - 1],     ni: i,     nj: j - 1 },
    ];
    options.sort((a, b) => a.cost - b.cost);
    i = options[0].ni;
    j = options[0].nj;
  }

  return pathLen > 0 ? D[n][m] / pathLen : D[n][m];
}

/**
 * Convert a DTW distance into a 0–100 similarity percentage.
 *
 * Mapping:
 *   distance = 0             → 100%
 *   distance ≥ DTW_MAX_DIST  → 0%
 *   linear interpolation in between
 *
 * @param {number} dtwDist
 * @returns {number} 0–100
 */
function dtwToSimilarity(dtwDist) {
  if (dtwDist <= 0) return 100;
  if (dtwDist >= DTW_MAX_DISTANCE) return 0;
  return Math.round(100 * (1 - dtwDist / DTW_MAX_DISTANCE));
}

// ═══════════════════════════════════════════════════════════════════════
// Directional Vector Analysis
// ═══════════════════════════════════════════════════════════════════════

/**
 * Compute the "dominant direction" of a stroke as a unit vector.
 *
 * We use the timestamp-ordered first and last point to determine
 * the direction. For a stroke drawn top→bottom the vector points
 * downward; drawn bottom→top it points upward.
 *
 * @param {Array<{x:number,y:number,t:number}>} points — resampled
 * @returns {{dx:number, dy:number}}  Unit vector (or zero vector if degenerate)
 */
function dominantDirection(points) {
  if (points.length < 2) return { dx: 0, dy: 0 };

  // Sort by timestamp to handle out-of-order edge cases
  const sorted = [...points].sort((a, b) => a.t - b.t);
  const first = sorted[0];
  const last = sorted[sorted.length - 1];

  const dx = last.x - first.x;
  const dy = last.y - first.y;
  const mag = Math.sqrt(dx * dx + dy * dy);

  if (mag === 0) return { dx: 0, dy: 0 };
  return { dx: dx / mag, dy: dy / mag };
}

/**
 * Compute the cosine similarity between two 2D vectors.
 *
 * cos(θ) = (a · b) / (|a| |b|)
 *
 * Returns 1 for parallel, 0 for perpendicular, -1 for anti-parallel.
 *
 * @param {{dx:number,dy:number}} a
 * @param {{dx:number,dy:number}} b
 * @returns {number} -1 to 1
 */
function cosineSimilarity(a, b) {
  const dot = a.dx * b.dx + a.dy * b.dy;
  const magA = Math.sqrt(a.dx * a.dx + a.dy * a.dy);
  const magB = Math.sqrt(b.dx * b.dx + b.dy * b.dy);
  if (magA === 0 || magB === 0) return 0;
  return dot / (magA * magB);
}

/**
 * Fine-grained segment-by-segment direction comparison with smoothing.
 *
 * Divides both the user stroke and standard stroke into segments
 * (between consecutive resampled points), computes direction vectors
 * using a 3-point sliding window for noise reduction, and averages
 * the cosine similarity across all segment pairs.
 *
 * The smoothing helps with complex curved characters (like ង) where
 * individual segments may vary significantly while the overall flow
 * is correct.
 *
 * @param {Array<{x:number,y:number}>} userPts  — resampled
 * @param {Array<{x:number,y:number}>} stdPts   — resampled
 * @returns {{avgCosine: number, reversedSegments: number, totalSegments: number}}
 */
function segmentDirectionAnalysis(userPts, stdPts) {
  const n = Math.min(userPts.length, stdPts.length) - 1;
  if (n <= 0) return { avgCosine: 0, reversedSegments: 0, totalSegments: 0 };

  // Use 3-point smoothed direction vectors to reduce noise
  const SMOOTH_WINDOW = 2; // look-ahead distance for smoothed direction

  let cosineSum = 0;
  let reversedCount = 0;
  let validSegments = 0;

  for (let i = 0; i < n; i++) {
    // Smoothed direction: use point i to point i+SMOOTH_WINDOW (clamped)
    const uEnd = Math.min(i + SMOOTH_WINDOW, userPts.length - 1);
    const sEnd = Math.min(i + SMOOTH_WINDOW, stdPts.length - 1);

    const uDir = {
      dx: userPts[uEnd].x - userPts[i].x,
      dy: userPts[uEnd].y - userPts[i].y,
    };
    const sDir = {
      dx: stdPts[sEnd].x - stdPts[i].x,
      dy: stdPts[sEnd].y - stdPts[i].y,
    };

    // Skip degenerate segments where both vectors are near-zero
    const uMag = Math.sqrt(uDir.dx * uDir.dx + uDir.dy * uDir.dy);
    const sMag = Math.sqrt(sDir.dx * sDir.dx + sDir.dy * sDir.dy);
    if (uMag < 0.01 || sMag < 0.01) continue;

    const cos = cosineSimilarity(uDir, sDir);
    cosineSum += cos;
    validSegments++;
    if (cos < DIRECTION_REVERSE_THRESHOLD) {
      reversedCount++;
    }
  }

  return {
    avgCosine: validSegments > 0 ? cosineSum / validSegments : 0,
    reversedSegments: reversedCount,
    totalSegments: validSegments,
  };
}

/**
 * Convert directional analysis results to a 0–100 score.
 *
 * Formula:
 *   score = clamp( (avgCosine + 1) / 2 * 100, 0, 100 )
 *
 * This maps cosine=-1 (fully reversed) → 0, cosine=1 (identical) → 100.
 *
 * @param {number} avgCosine  — average cosine similarity (-1 to 1)
 * @returns {number} 0–100
 */
function directionToScore(avgCosine) {
  return Math.round(Math.max(0, Math.min(100, ((avgCosine + 1) / 2) * 100)));
}

// ═══════════════════════════════════════════════════════════════════════
// Stroke Matching (Optimal Pairing)
// ═══════════════════════════════════════════════════════════════════════

/**
 * Match user strokes to standard strokes using a greedy best-fit
 * algorithm based on centroid proximity.
 *
 * Why centroid matching?
 *   Children may not draw strokes in the canonical order. A greedy
 *   pairing by spatial proximity is more forgiving than strict order.
 *
 * @param {Array<Array<{x:number,y:number}>>} userStrokes   — normalized
 * @param {Array<Array<{x:number,y:number}>>} stdStrokes    — normalized
 * @returns {Array<{userIdx:number, stdIdx:number, distance:number}>}
 */
function matchStrokes(userStrokes, stdStrokes) {
  const used = new Set();
  const pairs = [];

  // For each standard stroke, find the closest unmatched user stroke
  for (let si = 0; si < stdStrokes.length; si++) {
    const stdCenter = centroid(stdStrokes[si]);
    let bestIdx = -1;
    let bestDist = Infinity;

    for (let ui = 0; ui < userStrokes.length; ui++) {
      if (used.has(ui)) continue;
      const userCenter = centroid(userStrokes[ui]);
      const d = dist(stdCenter, userCenter);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = ui;
      }
    }

    if (bestIdx >= 0) {
      pairs.push({ userIdx: bestIdx, stdIdx: si, distance: bestDist });
      used.add(bestIdx);
    }
  }

  return pairs;
}

// ═══════════════════════════════════════════════════════════════════════
// Feedback Generator
// ═══════════════════════════════════════════════════════════════════════

/**
 * Generate a child-friendly Vietnamese feedback string.
 *
 * @param {Object} params
 * @param {number} params.strokeCountScore
 * @param {number} params.shapeScore
 * @param {number} params.directionScore
 * @param {number} params.similarityScore — composite
 * @param {Array<{strokeIndex:number, type:string, detail:string}>} params.issues
 * @returns {{feedback:string, errorStrokeIndex:number}}
 */
function generateFeedback({ strokeCountScore, shapeScore, directionScore, similarityScore, issues }) {
  // Sort issues by severity (missing stroke > reversed > shape)
  const sortedIssues = [...issues].sort((a, b) => {
    const priority = { missing_stroke: 0, reversed: 1, shape: 2 };
    return (priority[a.type] ?? 3) - (priority[b.type] ?? 3);
  });

  let feedback = '';
  let errorStrokeIndex = -1;

  if (sortedIssues.length === 0) {
    // Perfect or near-perfect
    if (similarityScore >= 90) {
      feedback = 'Tuyệt vời! Con viết rất giống mẫu! 🌟';
    } else if (similarityScore >= 70) {
      feedback = 'Khá tốt rồi! Cố gắng thêm chút nữa nhé! 👍';
    } else {
      feedback = 'Cần luyện tập thêm. Quan sát mẫu rồi viết lại nhé! 💪';
    }
  } else {
    // Pick the most severe issue for primary feedback
    const primary = sortedIssues[0];
    errorStrokeIndex = primary.strokeIndex;

    switch (primary.type) {
      case 'missing_stroke':
        feedback = primary.detail;
        break;
      case 'extra_stroke':
        feedback = primary.detail;
        break;
      case 'reversed':
        feedback = primary.detail;
        break;
      case 'shape':
        feedback = primary.detail;
        break;
      default:
        feedback = 'Hãy quan sát mẫu và viết lại nhé!';
    }
  }

  return { feedback, errorStrokeIndex };
}

// ═══════════════════════════════════════════════════════════════════════
// Main Analyzer
// ═══════════════════════════════════════════════════════════════════════

/**
 * Analyze a child's handwriting strokes against the standard (golden path).
 *
 * This is the sole public entry point. It orchestrates:
 *   1. Normalization & resampling
 *   2. Stroke count comparison
 *   3. Per-stroke DTW shape comparison
 *   4. Per-stroke directional alignment
 *   5. Weighted score aggregation
 *   6. Feedback generation
 *
 * @param {Object} params
 * @param {Array<Array<{x:number,y:number,t:number}>>} params.userStrokes
 *   Raw stroke data from the child's drawing.
 *   Outer array = strokes, inner array = ordered points.
 *
 * @param {Array<Array<{x:number,y:number,t:number}>>} params.standardStrokes
 *   Golden path strokes from the StandardCharacter document.
 *
 * @param {string} [params.character='']
 *   The target character (for logging / feedback).
 *
 * @returns {{
 *   success: boolean,
 *   similarityScore: number,    // 0–100 composite
 *   shapeScore: number,         // 0–100
 *   directionScore: number,     // 0–100
 *   strokeCountScore: number,   // 0–100
 *   feedback: string,           // Vietnamese child-friendly text
 *   errorStrokeIndex: number,   // -1 if none, else 0-based index
 *   errors: string[],           // all detected issue descriptions
 *   details: Object,            // per-stroke breakdown (for debugging)
 * }}
 */
/**
 * Helper: Run standard stroke-by-stroke analysis.
 */
function analyzeStrokesStandard({ userStrokes, standardStrokes, character = '' }) {
  // ── 1. Normalize ────────────────────────────────────────────────
  const normUser = normalizeStrokes(userStrokes);
  const normStd = normalizeStrokes(standardStrokes);

  // ── 2. Resample ─────────────────────────────────────────────────
  const resampledUser = normUser.map((s) => resampleStroke(s, RESAMPLE_COUNT));
  const resampledStd = normStd.map((s) => resampleStroke(s, RESAMPLE_COUNT));

  // ── 3. Stroke Count Analysis ────────────────────────────────────
  const expectedCount = resampledStd.length;
  const actualCount = resampledUser.length;

  let strokeCountScore = 100;
  const issues = [];

  // ── 4. Match user strokes to standard strokes ───────────────────
  const pairs = matchStrokes(resampledUser, resampledStd);

  // ── 5. Per-pair DTW + Direction analysis ────────────────────────
  const strokeDetails = [];
  let totalShapeScore = 0;
  let totalDirScore = 0;
  let pairedCount = 0;

  for (const pair of pairs) {
    const uStroke = resampledUser[pair.userIdx];
    const sStroke = resampledStd[pair.stdIdx];

    // --- Shape (DTW) ---
    const dtwDist = dtwDistance(uStroke, sStroke);
    const shapeSim = dtwToSimilarity(dtwDist);
    totalShapeScore += shapeSim;

    // --- Direction ---
    const userDir = dominantDirection(uStroke);
    const stdDir = dominantDirection(sStroke);
    const dominantCos = cosineSimilarity(userDir, stdDir);
    const segAnalysis = segmentDirectionAnalysis(uStroke, sStroke);
    const dirScore = directionToScore(segAnalysis.avgCosine);
    totalDirScore += dirScore;

    pairedCount++;

    // Record issues
    if (dominantCos < DIRECTION_REVERSE_THRESHOLD) {
      const stdDirLabel = getDirLabel(stdDir);
      issues.push({
        strokeIndex: pair.stdIdx,
        type: 'reversed',
        detail: `Con vẽ nét thứ ${pair.stdIdx + 1} bị ngược hướng rồi, ${stdDirLabel}!`,
      });
    }

    if (shapeSim < 40) {
      issues.push({
        strokeIndex: pair.stdIdx,
        type: 'shape',
        detail: `Nét thứ ${pair.stdIdx + 1} chưa giống mẫu lắm, con quan sát kỹ rồi viết lại nhé!`,
      });
    }

    strokeDetails.push({
      userStrokeIndex: pair.userIdx,
      stdStrokeIndex: pair.stdIdx,
      shapeSimilarity: shapeSim,
      dtwDistance: Math.round(dtwDist * 100) / 100,
      dominantCosine: Math.round(dominantCos * 1000) / 1000,
      segmentAvgCosine: Math.round(segAnalysis.avgCosine * 1000) / 1000,
      reversedSegments: segAnalysis.reversedSegments,
      totalSegments: segAnalysis.totalSegments,
      directionScore: dirScore,
    });
  }

  // ── 6. Aggregate scores ─────────────────────────────────────────
  const avgShapeScore = pairedCount > 0
    ? Math.round(totalShapeScore / pairedCount)
    : 0;
  const avgDirScore = pairedCount > 0
    ? Math.round(totalDirScore / pairedCount)
    : 0;

  // Only penalize missing standard strokes (unmatchedStdCount). Do not penalize extra user strokes.
  const unmatchedStdCount = expectedCount - pairedCount;
  const matchPenalty = unmatchedStdCount > 0
    ? Math.max(0, avgShapeScore - (unmatchedStdCount * 15))
    : avgShapeScore;

  const compositeSimilarity = Math.round(
    WEIGHTS.shape * matchPenalty +
    WEIGHTS.direction * avgDirScore +
    WEIGHTS.strokeCount * strokeCountScore
  );

  const clampedScore = Math.max(0, Math.min(100, compositeSimilarity));

  // ── 7. Generate feedback ────────────────────────────────────────
  const { feedback, errorStrokeIndex } = generateFeedback({
    strokeCountScore,
    shapeScore: avgShapeScore,
    directionScore: avgDirScore,
    similarityScore: clampedScore,
    issues,
  });

  return {
    success: true,
    similarityScore: clampedScore,
    shapeScore: avgShapeScore,
    directionScore: avgDirScore,
    strokeCountScore,
    feedback,
    errorStrokeIndex,
    errors: issues.map((i) => i.detail),
    details: {
      expectedStrokes: expectedCount,
      actualStrokes: actualCount,
      pairedStrokes: pairedCount,
      strokeDetails,
    },
  };
}

/**
 * Helper: Run unified flattened-path analysis by merging all strokes.
 * This provides extreme tolerance for varying stroke counts (e.g. 1 stroke instead of 2).
 */
function analyzeStrokesFlattened({ userStrokes, standardStrokes, character = '' }) {
  // Flatten user and standard points into single unified paths
  const flatUserPoints = userStrokes.flat();
  const flatStdPoints = standardStrokes.flat();

  // Normalize as single strokes
  const normUser = normalizeStrokes([flatUserPoints])[0];
  const normStd = normalizeStrokes([flatStdPoints])[0];

  // Resample unified paths to 96 points for better shape fidelity with complex characters
  const userPts = resampleStroke(normUser, 96);
  const stdPts = resampleStroke(normStd, 96);

  // --- Shape (DTW) ---
  const dtwDist = dtwDistance(userPts, stdPts);
  const shapeSim = dtwToSimilarity(dtwDist);

  // --- Direction ---
  const userDir = dominantDirection(userPts);
  const stdDir = dominantDirection(stdPts);
  const dominantCos = cosineSimilarity(userDir, stdDir);
  const segAnalysis = segmentDirectionAnalysis(userPts, stdPts);
  const dirScore = directionToScore(segAnalysis.avgCosine);

  // Stroke count is perfectly flexible here, so count score is 100
  const strokeCountScore = 100;

  // Composite Similarity
  const compositeSimilarity = Math.round(
    WEIGHTS.shape * shapeSim +
    WEIGHTS.direction * dirScore +
    WEIGHTS.strokeCount * strokeCountScore
  );
  const clampedScore = Math.max(0, Math.min(100, compositeSimilarity));

  const issues = [];
  if (dominantCos < DIRECTION_REVERSE_THRESHOLD) {
    const stdDirLabel = getDirLabel(stdDir);
    issues.push({
      strokeIndex: 0,
      type: 'reversed',
      detail: `Con vẽ nét chữ bị ngược hướng rồi, ${stdDirLabel}!`,
    });
  }
  if (shapeSim < 40) {
    issues.push({
      strokeIndex: 0,
      type: 'shape',
      detail: 'Nét chữ chưa giống mẫu lắm, con quan sát kỹ rồi viết lại nhé!',
    });
  }

  const { feedback, errorStrokeIndex } = generateFeedback({
    strokeCountScore,
    shapeScore: shapeSim,
    directionScore: dirScore,
    similarityScore: clampedScore,
    issues,
  });

  return {
    success: true,
    similarityScore: clampedScore,
    shapeScore: shapeSim,
    directionScore: dirScore,
    strokeCountScore,
    feedback,
    errorStrokeIndex: issues.length > 0 ? 0 : -1,
    errors: issues.map((i) => i.detail),
    details: {
      expectedStrokes: standardStrokes.length,
      actualStrokes: userStrokes.length,
      pairedStrokes: 1,
      strokeDetails: [
        {
          userStrokeIndex: 0,
          stdStrokeIndex: 0,
          shapeSimilarity: shapeSim,
          dtwDistance: Math.round(dtwDist * 100) / 100,
          dominantCosine: Math.round(dominantCos * 1000) / 1000,
          segmentAvgCosine: Math.round(segAnalysis.avgCosine * 1000) / 1000,
          reversedSegments: segAnalysis.reversedSegments,
          totalSegments: segAnalysis.totalSegments,
          directionScore: dirScore,
        }
      ],
    },
  };
}

function analyzeStrokes({ userStrokes, standardStrokes, character = '' }) {
  // ── Guard: empty input ──────────────────────────────────────────
  if (!userStrokes || userStrokes.length === 0) {
    return {
      success: false,
      similarityScore: 0,
      shapeScore: 0,
      directionScore: 0,
      strokeCountScore: 0,
      feedback: 'Con chưa viết gì cả, hãy thử viết nhé! ✏️',
      errorStrokeIndex: -1,
      errors: ['No strokes provided'],
      details: {},
    };
  }

  if (!standardStrokes || standardStrokes.length === 0) {
    return {
      success: false,
      similarityScore: 0,
      shapeScore: 0,
      directionScore: 0,
      strokeCountScore: 0,
      feedback: 'Không tìm thấy mẫu chuẩn cho ký tự này.',
      errorStrokeIndex: -1,
      errors: ['No standard strokes available'],
      details: {},
    };
  }

  // Run standard matching and unified flattened-path matching
  const standardResult = analyzeStrokesStandard({ userStrokes, standardStrokes, character });
  const flattenedResult = analyzeStrokesFlattened({ userStrokes, standardStrokes, character });

  // Use the one that achieves the higher similarityScore
  let bestResult;
  if (flattenedResult.similarityScore > standardResult.similarityScore) {
    bestResult = flattenedResult;
  } else {
    bestResult = standardResult;
  }

  // ── Complexity bonus ──────────────────────────────────────────
  // For characters with many direction changes (complex curves, loops),
  // exact DTW/direction matching is inherently harder. Apply a mild
  // bonus to account for the natural variation in handwriting.
  const totalStdPoints = standardStrokes.flat().length;
  if (totalStdPoints >= 15) {
    // Complex character (many control points → many curves)
    const complexityFactor = Math.min(totalStdPoints / 30, 1.0); // 0..1
    const bonus = Math.round(complexityFactor * 10); // up to +10
    bestResult.similarityScore = Math.min(100, bestResult.similarityScore + bonus);
    bestResult.shapeScore = Math.min(100, bestResult.shapeScore + bonus);
  }

  // Clamp all output scores between 0 and 100 to guarantee database validation matches boundaries
  bestResult.similarityScore = Math.max(0, Math.min(100, bestResult.similarityScore || 0));
  bestResult.shapeScore = Math.max(0, Math.min(100, bestResult.shapeScore || 0));
  bestResult.directionScore = Math.max(0, Math.min(100, bestResult.directionScore || 0));
  bestResult.strokeCountScore = Math.max(0, Math.min(100, bestResult.strokeCountScore || 0));

  return bestResult;
}

// ═══════════════════════════════════════════════════════════════════════
// Helper: Human-readable direction label (Vietnamese)
// ═══════════════════════════════════════════════════════════════════════

/**
 * Convert a unit direction vector to a Vietnamese instruction.
 * @param {{dx:number, dy:number}} dir
 * @returns {string}
 */
function getDirLabel(dir) {
  const absDx = Math.abs(dir.dx);
  const absDy = Math.abs(dir.dy);

  if (absDy > absDx) {
    // Primarily vertical
    return dir.dy > 0
      ? 'kéo từ trên xuống nhé'
      : 'kéo từ dưới lên nhé';
  } else {
    // Primarily horizontal
    return dir.dx > 0
      ? 'kéo từ trái sang phải nhé'
      : 'kéo từ phải sang trái nhé';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Exports
// ═══════════════════════════════════════════════════════════════════════

module.exports = {
  analyzeStrokes,

  // Exported for unit testing
  _internals: {
    resampleStroke,
    normalizeStrokes,
    dtwDistance,
    dtwToSimilarity,
    dominantDirection,
    cosineSimilarity,
    segmentDirectionAnalysis,
    directionToScore,
    matchStrokes,
    dist,
    pathLength,
    centroid,
    boundingBox,
    RESAMPLE_COUNT,
    NORM_SIZE,
    DTW_MAX_DISTANCE,
    WEIGHTS,
  },
};
