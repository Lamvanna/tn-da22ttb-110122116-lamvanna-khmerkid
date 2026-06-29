/**
 * ═══════════════════════════════════════════════════════════════════════
 * AI Vowel Stroke Analyzer — Optimized Geometric Engine for Khmer Vowels
 * ═══════════════════════════════════════════════════════════════════════
 *
 * Dedicated analyzer for Khmer vowel marks (srak).
 * Vowels are typically written smaller, have shorter strokes, and are 
 * often placed as accent marks relative to a carrier consonant.
 *
 * Optimization strategies:
 *   1. Reduced resampling (N=24 points): Better suited for short/simple strokes.
 *   2. Bounded scaling: Prevents tiny dots/ticks from being blown up and amplifying noise.
 *   3. Higher tolerance (DTW_MAX_DISTANCE = 160): More forgiving for kids' hands on small marks.
 *   4. Adjusted weights: Greater weight on overall shape and direction flow.
 */

'use strict';

const RESAMPLE_COUNT = 24;
const NORM_SIZE = 100;

const WEIGHTS = Object.freeze({
  shape: 0.50,
  direction: 0.35,
  strokeCount: 0.15,
});

const DIRECTION_REVERSE_THRESHOLD = -0.3;
const DTW_MAX_DISTANCE = 130;

// ═══════════════════════════════════════════════════════════════════════
// Geometry & Math Utilities
// ═══════════════════════════════════════════════════════════════════════

function dist(a, b) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return Math.sqrt(dx * dx + dy * dy);
}

function pathLength(points) {
  let total = 0;
  for (let i = 1; i < points.length; i++) {
    total += dist(points[i - 1], points[i]);
  }
  return total;
}

function centroid(points) {
  if (points.length === 0) return { x: 0, y: 0 };
  let sx = 0, sy = 0;
  for (const p of points) {
    sx += p.x;
    sy += p.y;
  }
  return { x: sx / points.length, y: sy / points.length };
}

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

function getPathLengthPenalty(userPts, stdPts) {
  const uLen = pathLength(userPts);
  const sLen = pathLength(stdPts);
  if (sLen === 0) return 0;

  const ratio = uLen / sLen;

  // Precise range [0.7, 1.35] optimized for Khmer vowel scale
  if (ratio >= 0.7 && ratio <= 1.35) {
    return 1.0;
  }

  if (ratio < 0.7) {
    // Too short (linear penalty, e.g. dot instead of line)
    return Math.max(0.1, ratio / 0.7);
  } else {
    // Too long (steep cubic penalty to completely crush extra lines/circles/scribbles)
    return Math.max(0.05, Math.pow(1.35 / ratio, 3.0));
  }
}


// ═══════════════════════════════════════════════════════════════════════
// Preprocessing (Vowel Optimized)
// ═══════════════════════════════════════════════════════════════════════

function resampleStroke(points, n = RESAMPLE_COUNT) {
  if (points.length === 0) return [];
  if (points.length === 1) {
    return Array.from({ length: n }, () => ({ ...points[0] }));
  }

  const totalLen = pathLength(points);
  if (totalLen === 0) {
    return Array.from({ length: n }, () => ({ ...points[0] }));
  }

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
      const nt = pts[i - 1].t != null && pts[i].t != null
        ? pts[i - 1].t + ratio * (pts[i].t - pts[i - 1].t)
        : 0;

      const newPt = { x: nx, y: ny, t: Math.round(nt) };
      resampled.push(newPt);

      pts[i - 1] = newPt;
      accum = 0;
    } else {
      accum += d;
      i++;
    }
  }

  while (resampled.length < n) {
    resampled.push({ ...pts[pts.length - 1] });
  }

  return resampled.slice(0, n);
}

/**
 * Normalize strokes with bounding box limit.
 * Prevents small loops/dots from scaling up to 100x100, which preserves shape.
 */
function normalizeStrokes(strokes) {
  const allPoints = strokes.flat();
  if (allPoints.length === 0) return strokes;

  const bb = boundingBox(allPoints);
  const maxDim = Math.max(bb.width, bb.height);

  if (maxDim === 0) {
    return strokes.map((s) =>
      s.map((p) => ({ x: NORM_SIZE / 2, y: NORM_SIZE / 2, t: p.t || 0 }))
    );
  }

  // Use a minimum scale threshold of 30 units to avoid over-scaling tiny marks
  const scale = NORM_SIZE / Math.max(30, maxDim);

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

function dtwDistance(s1, s2) {
  const n = s1.length;
  const m = s2.length;
  if (n === 0 || m === 0) return Infinity;

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

  let pathLen = 0;
  let i = n, j = m;
  while (i > 0 || j > 0) {
    pathLen++;
    if (i === 0) { j--; continue; }
    if (j === 0) { i--; continue; }
    const options = [
      { cost: D[i - 1][j - 1], ni: i - 1, nj: j - 1 },
      { cost: D[i - 1][j], ni: i - 1, nj: j },
      { cost: D[i][j - 1], ni: i, nj: j - 1 },
    ];
    options.sort((a, b) => a.cost - b.cost);
    i = options[0].ni;
    j = options[0].nj;
  }

  return pathLen > 0 ? D[n][m] / pathLen : D[n][m];
}

function dtwToSimilarity(dtwDist) {
  if (dtwDist <= 0) return 100;
  if (dtwDist >= DTW_MAX_DISTANCE) return 0;
  return Math.round(100 * (1 - dtwDist / DTW_MAX_DISTANCE));
}

// ═══════════════════════════════════════════════════════════════════════
// Directional Vector Analysis
// ═══════════════════════════════════════════════════════════════════════

function dominantDirection(points) {
  if (points.length < 2) return { dx: 0, dy: 0 };

  const sorted = [...points].sort((a, b) => a.t - b.t);
  const first = sorted[0];
  const last = sorted[sorted.length - 1];

  const dx = last.x - first.x;
  const dy = last.y - first.y;
  const mag = Math.sqrt(dx * dx + dy * dy);

  if (mag === 0) return { dx: 0, dy: 0 };
  return { dx: dx / mag, dy: dy / mag };
}

function cosineSimilarity(a, b) {
  const dot = a.dx * b.dx + a.dy * b.dy;
  const magA = Math.sqrt(a.dx * a.dx + a.dy * a.dy);
  const magB = Math.sqrt(b.dx * b.dx + b.dy * b.dy);
  if (magA === 0 || magB === 0) return 0;
  return dot / (magA * magB);
}

function segmentDirectionAnalysis(userPts, stdPts) {
  const n = Math.min(userPts.length, stdPts.length) - 1;
  if (n <= 0) return { avgCosine: 0, reversedSegments: 0, totalSegments: 0 };

  const SMOOTH_WINDOW = 2;
  let cosineSum = 0;
  let reversedCount = 0;
  let validSegments = 0;

  for (let i = 0; i < n; i++) {
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

function strokeSmoothness(stroke) {
  const vectors = [];
  for (let i = 0; i < stroke.length - 1; i++) {
    const dx = stroke[i + 1].x - stroke[i].x;
    const dy = stroke[i + 1].y - stroke[i].y;
    vectors.push({ dx, dy });
  }
  const cosines = [];
  for (let i = 0; i < vectors.length - 1; i++) {
    const v1 = vectors[i];
    const v2 = vectors[i + 1];
    const dot = v1.dx * v2.dx + v1.dy * v2.dy;
    const mag1 = Math.sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
    const mag2 = Math.sqrt(v2.dx * v2.dx + v2.dy * v2.dy);
    if (mag1 > 0.0001 && mag2 > 0.0001) {
      cosines.push(dot / (mag1 * mag2));
    }
  }
  if (cosines.length === 0) return { avgCos: 1.0, negativeCosines: 0 };
  const avgCos = cosines.reduce((sum, c) => sum + c, 0) / cosines.length;
  const negativeCosines = cosines.filter(c => c < 0).length;
  return { avgCos, negativeCosines };
}

function directionToScore(avgCosine) {
  if (avgCosine >= 0.7) return 100;
  if (avgCosine <= 0) return 0;
  return Math.round(100 * Math.pow(avgCosine / 0.7, 1.5));
}

// ═══════════════════════════════════════════════════════════════════════
// Stroke Matching
// ═══════════════════════════════════════════════════════════════════════

function matchStrokes(userStrokes, stdStrokes) {
  const used = new Set();
  const pairs = [];

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
// Vowel-specific Feedback Generator
// ═══════════════════════════════════════════════════════════════════════

function generateVowelFeedback({ strokeCountScore, shapeScore, directionScore, similarityScore, issues, character }) {
  const sortedIssues = [...issues].sort((a, b) => {
    const priority = { missing_stroke: 0, reversed: 1, shape: 2 };
    return (priority[a.type] ?? 3) - (priority[b.type] ?? 3);
  });

  let feedback = '';
  let errorStrokeIndex = -1;

  if (sortedIssues.length === 0) {
    if (similarityScore >= 85) {
      feedback = 'Tuyệt vời! Con viết nét nguyên âm rất đẹp! 🌟';
    } else if (similarityScore >= 65) {
      feedback = 'Khá tốt rồi! Nét nguyên âm rất rõ ràng! 👍';
    } else {
      feedback = 'Nét vẽ chưa giống mẫu lắm. Hãy luyện tập thêm nhé! 💪';
    }
  } else {
    const primary = sortedIssues[0];
    errorStrokeIndex = primary.strokeIndex;
    feedback = primary.detail;
  }

  return { feedback, errorStrokeIndex };
}

// ═══════════════════════════════════════════════════════════════════════
// Main Vowel Analyzer
// ═══════════════════════════════════════════════════════════════════════

function analyzeVowelStrokes({ userStrokes, standardStrokes, character = '' }) {
  if (!userStrokes || userStrokes.length === 0) {
    return {
      success: false,
      similarityScore: 0,
      shapeScore: 0,
      directionScore: 0,
      strokeCountScore: 0,
      feedback: 'Con chưa viết gì cả, hãy vẽ nét nguyên âm nhé! ✏️',
      errorStrokeIndex: -1,
      errors: ['No strokes provided'],
      details: {},
    };
  }

  // Normalize
  const normUser = normalizeStrokes(userStrokes);
  const normStd = normalizeStrokes(standardStrokes);

  // Resample
  const resampledUser = normUser.map((s) => resampleStroke(s, RESAMPLE_COUNT));
  const resampledStd = normStd.map((s) => resampleStroke(s, RESAMPLE_COUNT));

  const expectedCount = resampledStd.length;
  const actualCount = resampledUser.length;

  let strokeCountScore = 100;
  // Stricter stroke count penalty for vowels to prevent letter overlap (ិ vs ី vs ឹ vs ឺ)
  if (expectedCount !== actualCount) {
    strokeCountScore = Math.max(0, 100 - Math.abs(expectedCount - actualCount) * 50);
  }

  const pairs = matchStrokes(resampledUser, resampledStd);
  const issues = [];
  const strokeDetails = [];
  let totalShapeScore = 0;
  let totalDirScore = 0;
  let pairedCount = 0;

  for (const pair of pairs) {
    const uStroke = resampledUser[pair.userIdx];
    const sStroke = resampledStd[pair.stdIdx];

    const userDir = dominantDirection(uStroke);
    const stdDir = dominantDirection(sStroke);
    const dominantCos = cosineSimilarity(userDir, stdDir);
    const segAnalysis = segmentDirectionAnalysis(uStroke, sStroke);
    let dirScore = directionToScore(segAnalysis.avgCosine);

    const dtwDist = dtwDistance(uStroke, sStroke);
    let shapeSim = dtwToSimilarity(dtwDist);
    const lengthPenalty = getPathLengthPenalty(uStroke, sStroke);
    shapeSim = Math.round(shapeSim * lengthPenalty);

    // Apply direction penalty to shapeSim if segment alignment is poor (e.g. jagged/saw-tooth lines)
    const dirPenalty = segAnalysis.avgCosine >= 0.6
      ? 1.0
      : Math.max(0.2, Math.pow(segAnalysis.avgCosine / 0.6, 2.0));
    shapeSim = Math.round(shapeSim * dirPenalty);

    // Calculate smoothness & direction reversal penalties
    const uSmooth = strokeSmoothness(uStroke);
    const sSmooth = strokeSmoothness(sStroke);

    let smoothnessPenalty = 1.0;
    if (sSmooth.avgCos >= 0.75 && uSmooth.avgCos < sSmooth.avgCos) {
      const deviation = 0.75 - uSmooth.avgCos;
      if (deviation > 0) {
        smoothnessPenalty = Math.max(0.1, 1.0 - deviation * 1.5);
      }
    }

    const extraNegatives = Math.max(0, uSmooth.negativeCosines - sSmooth.negativeCosines);
    let negPenalty = 1.0;
    if (extraNegatives === 1) {
      negPenalty = 0.90;
    } else if (extraNegatives === 2) {
      negPenalty = 0.60;
    } else if (extraNegatives === 3) {
      negPenalty = 0.30;
    } else if (extraNegatives >= 4) {
      negPenalty = 0.05;
    }

    const strokePenalty = smoothnessPenalty * negPenalty;
    shapeSim = Math.round(shapeSim * strokePenalty);
    dirScore = Math.round(dirScore * strokePenalty);

    totalShapeScore += shapeSim;
    totalDirScore += dirScore;

    pairedCount++;

    if (dominantCos < DIRECTION_REVERSE_THRESHOLD) {
      const stdDirLabel = getDirLabel(stdDir);
      issues.push({
        strokeIndex: pair.stdIdx,
        type: 'reversed',
        detail: `Nét nguyên âm thứ ${pair.stdIdx + 1} bị ngược rồi, ${stdDirLabel}!`,
      });
    } else if (strokePenalty < 0.75) {
      issues.push({
        strokeIndex: pair.stdIdx,
        type: 'shape',
        detail: `Nét nguyên âm thứ ${pair.stdIdx + 1} vẽ chưa được mượt mà, con hãy vẽ nắn nót hơn nhé!`,
      });
    } else if (shapeSim < 35) {
      issues.push({
        strokeIndex: pair.stdIdx,
        type: 'shape',
        detail: `Nét nguyên âm thứ ${pair.stdIdx + 1} chưa giống mẫu, con viết lại nhé!`,
      });
    }

    strokeDetails.push({
      userStrokeIndex: pair.userIdx,
      stdStrokeIndex: pair.stdIdx,
      shapeSimilarity: shapeSim,
      dtwDistance: Math.round(dtwDist * 100) / 100,
      dominantCosine: Math.round(dominantCos * 1000) / 1000,
      directionScore: dirScore,
    });
  }

  // Missing standard strokes or extra user strokes penalty (crucial for distinguishing similar vowels like ិ, ី, ឹ, ឺ)
  const unmatchedStdCount = expectedCount - pairedCount;
  const extraUserCount = actualCount - pairedCount;

  let matchPenalty = pairedCount > 0 ? (totalShapeScore / pairedCount) : 0;
  if (unmatchedStdCount > 0) {
    matchPenalty = Math.max(0, matchPenalty - (unmatchedStdCount * 45));
  }
  if (extraUserCount > 0) {
    matchPenalty = Math.max(0, matchPenalty - (extraUserCount * 50));
  }

  let avgDirScore = pairedCount > 0 ? (totalDirScore / pairedCount) : 0;
  if (unmatchedStdCount > 0) {
    avgDirScore = Math.max(0, avgDirScore - (unmatchedStdCount * 25));
  }

  const compositeSimilarity = Math.round(
    WEIGHTS.shape * matchPenalty +
    WEIGHTS.direction * avgDirScore +
    WEIGHTS.strokeCount * strokeCountScore
  );

  const clampedScore = Math.max(0, Math.min(100, compositeSimilarity));

  const { feedback, errorStrokeIndex } = generateVowelFeedback({
    strokeCountScore,
    shapeScore: matchPenalty,
    directionScore: avgDirScore,
    similarityScore: clampedScore,
    issues,
    character,
  });

  return {
    success: true,
    similarityScore: Math.max(0, Math.min(100, clampedScore)),
    shapeScore: Math.max(0, Math.min(100, Math.round(matchPenalty))),
    directionScore: Math.max(0, Math.min(100, Math.round(avgDirScore))),
    strokeCountScore: Math.max(0, Math.min(100, strokeCountScore)),
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

function getDirLabel(dir) {
  const absDx = Math.abs(dir.dx);
  const absDy = Math.abs(dir.dy);

  if (absDy > absDx) {
    return dir.dy > 0 ? 'kéo từ trên xuống dưới nhé' : 'kéo từ dưới lên trên nhé';
  } else {
    return dir.dx > 0 ? 'kéo từ trái sang phải nhé' : 'kéo từ phải sang trái nhé';
  }
}

module.exports = {
  analyzeVowelStrokes,
};
