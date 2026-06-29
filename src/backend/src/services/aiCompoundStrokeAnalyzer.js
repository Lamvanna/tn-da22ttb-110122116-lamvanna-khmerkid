/**
 * ═══════════════════════════════════════════════════════════════════════
 * AI Compound Stroke Analyzer — Geometric Analysis for Khmer Compound Chars
 * ═══════════════════════════════════════════════════════════════════════
 *
 * Dedicated geometric handwriting analysis engine for compound Khmer words,
 * numbers, and spelling syllables (e.g., "កា", "កិ", "កក់", "២៣").
 *
 * Since compound characters have too many combinations to seed golden paths
 * for all of them, this analyzer evaluates user drawings using pure geometric
 * heuristics:
 *   1. Stroke Count Range: Checks if number of strokes aligns with char length.
 *   2. Bounding Box & Canvas Coverage: Avoids tiny wiggles or dots.
 *   3. Centroid Distribution: Ensures strokes are spread out, not drawn on top of each other.
 *   4. Stroke Smoothness: Checks for erratic scribbles or high-frequency zigzags.
 *
 * This works in tandem with frontend ML Kit (Tier 1) recognition which serves
 * as the primary character validation.
 */

'use strict';

const RESAMPLE_COUNT = 24;
const NORM_SIZE = 100;

const WEIGHTS = Object.freeze({
  shape: 0.40,
  direction: 0.30,
  strokeCount: 0.30,
});

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

function isStrokeLoop(stroke) {
  if (stroke.length < 4) return false;

  const bb = boundingBox(stroke);
  const maxDim = Math.max(bb.width, bb.height);
  if (maxDim < 5) return false; // Too small to be a loop

  const pStart = stroke[0];
  const pEnd = stroke[stroke.length - 1];
  const dStartEnd = dist(pStart, pEnd);

  // Start and end must be close relative to the stroke size
  if (dStartEnd / maxDim > 0.35) {
    return false;
  }

  // Calculate swept angle around centroid
  const c = centroid(stroke);
  let totalAngle = 0;
  for (let i = 0; i < stroke.length - 1; i++) {
    const p1 = stroke[i];
    const p2 = stroke[i + 1];
    const a1 = Math.atan2(p1.y - c.y, p1.x - c.x);
    const a2 = Math.atan2(p2.y - c.y, p2.x - c.x);
    let diff = a2 - a1;
    while (diff < -Math.PI) diff += 2 * Math.PI;
    while (diff > Math.PI) diff -= 2 * Math.PI;
    totalAngle += diff;
  }

  return Math.abs(totalAngle) > 4.5;
}

function isStrokeScribble(stroke) {
  if (stroke.length < 4) return false;
  const bb = boundingBox(stroke);
  const diag = Math.sqrt(bb.width * bb.width + bb.height * bb.height);
  if (diag < 5) return false; // Too small to be a scribble
  const len = pathLength(stroke);
  const ratio = len / diag;
  return ratio > 3.8;
}

const DIRECTION_REVERSE_THRESHOLD = -0.3;
const DTW_MAX_DISTANCE = 130;

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
// Preprocessing & Normalization
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
// Smoothness & Direction Utilities
// ═══════════════════════════════════════════════════════════════════════

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
// Main Compound Analyzer
// ═══════════════════════════════════════════════════════════════════════

function analyzeCompoundStrokes({ userStrokes, character = '', componentStrokeCounts = [], componentStandardStrokes = [] }) {
  if (!userStrokes || userStrokes.length === 0) {
    return {
      success: false,
      similarityScore: 0,
      shapeScore: 0,
      directionScore: 0,
      strokeCountScore: 0,
      feedback: 'Con chưa viết gì cả, hãy viết chữ ghép nhé! ✏️',
      errorStrokeIndex: -1,
      errors: ['No strokes provided'],
      details: {},
    };
  }

  const cleanChar = character.trim().replace(/\u25CC/g, '');
  const charLength = Math.max(1, cleanChar.length);

  const rawPoints = userStrokes.flat();
  const rawBB = boundingBox(rawPoints);
  const rawMaxDim = Math.max(rawBB.width, rawBB.height);

  // 1. Stroke Count Score
  let minExpected = Math.max(1, charLength);
  let maxExpected = charLength * 3;
  let totalStdStrokes = charLength * 2;

  if (componentStrokeCounts && componentStrokeCounts.length > 0) {
    totalStdStrokes = componentStrokeCounts.reduce((a, b) => a + b, 0);
    minExpected = Math.max(componentStrokeCounts.length + 1, Math.ceil(totalStdStrokes * 0.6));
    maxExpected = totalStdStrokes + Math.max(2, componentStrokeCounts.length * 2);
  }

  let strokeCountScore = 100;
  const isIncomplete = userStrokes.length < minExpected;

  if (isIncomplete) {
    strokeCountScore = Math.max(0, 100 - (minExpected - userStrokes.length) * 35);
  } else if (userStrokes.length > maxExpected) {
    strokeCountScore = Math.max(0, 100 - (userStrokes.length - maxExpected) * 15);
  }

  // Normalize & Resample
  const normUser = normalizeStrokes(userStrokes);
  const resampledUser = normUser.map((s) => resampleStroke(s, RESAMPLE_COUNT));

  // Loop detection check
  const loopChars = ['០', 'ំ', 'ះ', 'ៈ', '៎', '៏', '៌', '៍', 'ឹ', 'ឺ', 'ូ', 'ិ', 'ី'];
  const isLoopAllowed = loopChars.some((lc) => cleanChar.includes(lc));

  let hasUnexpectedLoop = false;
  if (!isLoopAllowed) {
    for (const stroke of resampledUser) {
      if (isStrokeLoop(stroke)) {
        hasUnexpectedLoop = true;
        break;
      }
    }
  }

  const rawDiag = Math.sqrt(rawBB.width * rawBB.width + rawBB.height * rawBB.height);
  const totalPathLen = userStrokes.reduce((sum, s) => sum + pathLength(s), 0);
  const entireRatio = rawDiag > 0 ? (totalPathLen / rawDiag) : 0;

  let hasScribble = entireRatio > 4.0 && rawDiag > 10;
  if (!hasScribble) {
    for (const stroke of normUser) {
      if (isStrokeScribble(stroke)) {
        hasScribble = true;
        break;
      }
    }
  }

  // 2. Shape Score (based on size, aspect ratio, and distribution)
  let shapeScore = 95;
  const issues = [];
  const errors = [];

  if (hasUnexpectedLoop) {
    shapeScore = Math.min(shapeScore, 15);
    errors.push('Nét vẽ tạo thành hình tròn/vòng lặp không khớp với chữ mẫu');
    issues.push({
      type: 'loop',
      detail: 'Con không nên vẽ hình tròn hoặc vòng lặp ở đây nhé! Hãy viết theo các nét của chữ mẫu. ✏️',
    });
  }

  if (isIncomplete) {
    shapeScore = Math.min(shapeScore, 20);
    errors.push('Chữ viết chưa hoàn thành hoặc thiếu nét');
    issues.push({
      type: 'incomplete',
      detail: 'Con viết chưa xong chữ ghép này, hãy viết đầy đủ cả phụ âm và nguyên âm nhé! ✏️',
    });
  }

  if (hasScribble) {
    shapeScore = Math.min(shapeScore, 15);
    errors.push('Nét vẽ có dấu hiệu nguệch ngoạc hoặc lặp nét nhiều lần');
    issues.push({
      type: 'scribble',
      detail: 'Con không nên vẽ nguệch ngoạc hoặc lặp nét nhiều lần nhé! Hãy viết nắn nót theo từng nét chữ mẫu. ✏️',
    });
  }

  // Tiny drawing check
  if (rawMaxDim < 30) {
    const penalty = Math.max(10, Math.round(rawMaxDim * 2.5));
    shapeScore = Math.min(shapeScore, penalty);
    errors.push('Chữ vẽ quá nhỏ hoặc chỉ là nét chấm');
    issues.push({
      type: 'size',
      detail: 'Con hãy viết chữ to và rõ hơn trong khung nhé! 🔍',
    });
  }

  // Aspect ratio skew check (single line spanning screen)
  if (rawMaxDim >= 30) {
    const ratio = rawBB.width / (rawBB.height || 1);
    if (ratio > 2.5 || ratio < 0.33) {
      shapeScore = Math.min(shapeScore, 15);
      errors.push('Nét vẽ bị lệch tỷ lệ quá mức hoặc quá dẹt');
      issues.push({
        type: 'aspect_ratio',
        detail: 'Con hãy viết chữ ghép cân đối và đẹp hơn nhé! ✏️',
      });
    }
  }

  // Centroid distribution check for multi-stroke compound words
  if (resampledUser.length >= 2) {
    const centroids = resampledUser.map(centroid);
    let totalDist = 0;
    let pairsCount = 0;
    for (let i = 0; i < centroids.length; i++) {
      for (let j = i + 1; j < centroids.length; j++) {
        totalDist += dist(centroids[i], centroids[j]);
        pairsCount++;
      }
    }
    const avgCentroidDistance = pairsCount > 0 ? (totalDist / pairsCount) : 0;
    
    // If strokes are all drawn directly on top of each other
    if (avgCentroidDistance < 6) {
      const overlapPenalty = Math.max(0.2, avgCentroidDistance / 6);
      shapeScore = Math.round(shapeScore * overlapPenalty);
      errors.push('Các nét vẽ chồng chéo tại một chỗ');
      issues.push({
        type: 'distribution',
        detail: 'Con chú ý viết các nét cách đều và cân đối nhé!',
      });
    }
  }

  // 3. Direction / Smoothness Score
  const smoothnesses = resampledUser.map(strokeSmoothness);
  const avgSmoothCos = smoothnesses.reduce((sum, s) => sum + s.avgCos, 0) / smoothnesses.length;
  const totalNegatives = smoothnesses.reduce((sum, s) => sum + s.negativeCosines, 0);

  let directionScore = Math.round(directionToScore(avgSmoothCos));
  const allowedNegatives = Math.floor(userStrokes.length * 0.5);
  if (totalNegatives > allowedNegatives) {
    directionScore = Math.max(10, directionScore - (totalNegatives - allowedNegatives) * 25);
  }

  if (hasUnexpectedLoop) {
    directionScore = Math.min(directionScore, 20);
  }

  if (isIncomplete) {
    directionScore = Math.min(directionScore, 20);
  }

  if (hasScribble) {
    directionScore = Math.min(directionScore, 20);
  }

  if (issues.some(iss => iss.type === 'aspect_ratio')) {
    directionScore = Math.min(directionScore, 20);
  }

  // Jaggedness check
  if (avgSmoothCos < 0.45 || totalNegatives > userStrokes.length * 4) {
    errors.push('Nét vẽ bị run hoặc quá ngoằn ngoèo');
    issues.push({
      type: 'smoothness',
      detail: 'Con hãy viết chậm lại và vẽ nét thật mượt mà nhé! ✏️',
    });
  }

  // 3b. Optional template-based shape matching if standard strokes of components are provided
  let templateShapeScore = 100;
  let templateDirectionScore = 100;
  let hasTemplateMatch = false;

  if (componentStandardStrokes && componentStandardStrokes.length > 0) {
    hasTemplateMatch = true;
    const normStd = normalizeStrokes(componentStandardStrokes);
    const resampledStd = normStd.map((s) => resampleStroke(s, RESAMPLE_COUNT));

    const pairs = matchStrokes(resampledUser, resampledStd);
    let totalShapeScore = 0;
    let totalDirScore = 0;
    let pairedCount = 0;

    for (const pair of pairs) {
      const uStroke = resampledUser[pair.userIdx];
      const sStroke = resampledStd[pair.stdIdx];

      // Translate standard stroke to align its centroid with the user stroke centroid
      const uCentroid = centroid(uStroke);
      const sCentroid = centroid(sStroke);
      const alignedStdStroke = sStroke.map((p) => ({
        x: p.x - sCentroid.x + uCentroid.x,
        y: p.y - sCentroid.y + uCentroid.y,
        t: p.t,
      }));

      const dtwDist = dtwDistance(uStroke, alignedStdStroke);
      let shapeSim = dtwToSimilarity(dtwDist);

      const userDir = dominantDirection(uStroke);
      const stdDir = dominantDirection(alignedStdStroke);
      const dominantCos = cosineSimilarity(userDir, stdDir);
      const segAnalysis = segmentDirectionAnalysis(uStroke, alignedStdStroke);
      let dirScore = directionToScore(segAnalysis.avgCosine);

      totalShapeScore += shapeSim;
      totalDirScore += dirScore;
      pairedCount++;
    }

    const expectedCount = resampledStd.length;
    const actualCount = resampledUser.length;
    const unmatchedStdCount = expectedCount - pairedCount;
    const extraUserCount = actualCount - pairedCount;

    let matchPenalty = pairedCount > 0 ? (totalShapeScore / pairedCount) : 0;
    if (unmatchedStdCount > 0) {
      matchPenalty = Math.max(0, matchPenalty - (unmatchedStdCount * 40));
    }
    if (extraUserCount > 0) {
      matchPenalty = Math.max(0, matchPenalty - (extraUserCount * 45));
    }

    let avgDirScore = pairedCount > 0 ? (totalDirScore / pairedCount) : 0;
    if (unmatchedStdCount > 0) {
      avgDirScore = Math.max(0, avgDirScore - (unmatchedStdCount * 20));
    }

    templateShapeScore = Math.round(matchPenalty);
    templateDirectionScore = Math.round(avgDirScore);

    // Apply template shape matching to clamp/reduce scores if drawn shapes mismatch
    shapeScore = Math.min(shapeScore, templateShapeScore);
    directionScore = Math.min(directionScore, templateDirectionScore);

    if (templateShapeScore < 60) {
      shapeScore = Math.min(shapeScore, 15);
      directionScore = Math.min(directionScore, 20);
      errors.push('Hình dạng nét vẽ không đúng với chữ ghép mẫu');
      issues.push({
        type: 'shape_mismatch',
        detail: 'Nét vẽ chưa giống chữ mẫu lắm, con hãy viết nắn nót hơn nhé! ✏️',
      });
    }
  }

  // 4. Composite Similarity Score
  const compositeScore = Math.round(
    WEIGHTS.shape * shapeScore +
    WEIGHTS.direction * directionScore +
    WEIGHTS.strokeCount * strokeCountScore
  );

  const finalScore = Math.max(0, Math.min(100, compositeScore));

  // Generate child-friendly feedback
  let feedback = 'Con ghép vần rất tốt! Chữ viết rất đều và đẹp. 🌟';
  let errorStrokeIndex = -1;

  if (issues.length > 0) {
    // Sort issues by priority
    const priority = { scribble: 0, loop: 1, incomplete: 2, aspect_ratio: 3, size: 4, distribution: 5, shape_mismatch: 6, smoothness: 7 };
    issues.sort((a, b) => (priority[a.type] ?? 5) - (priority[b.type] ?? 5));
    feedback = issues[0].detail;
  } else {
    if (finalScore >= 85) {
      feedback = 'Tuyệt vời! Con ghép vần rất giỏi! 🌟';
    } else if (finalScore >= 65) {
      feedback = 'Khá tốt rồi! Hãy tiếp tục luyện tập nhé! 👍';
    } else {
      feedback = 'Con viết nắn nót lại một chút cho đẹp nhé! 💪';
    }
  }

  return {
    success: finalScore >= 65,
    similarityScore: finalScore,
    shapeScore: Math.max(0, Math.min(100, Math.round(shapeScore))),
    directionScore: Math.max(0, Math.min(100, Math.round(directionScore))),
    strokeCountScore: Math.max(0, Math.min(100, Math.round(strokeCountScore))),
    feedback,
    errorStrokeIndex,
    errors,
    details: {
      rawBoundingBox: rawBB,
      strokeCount: userStrokes.length,
      expectedCountRange: [minExpected, maxExpected],
      avgSmoothCos,
      totalNegatives,
      entireRatio,
    },
  };
}

module.exports = {
  analyzeCompoundStrokes,
};
