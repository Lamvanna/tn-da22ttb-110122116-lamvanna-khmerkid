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

function analyzeCompoundStrokes({ userStrokes, character = '', componentStrokeCounts = [] }) {
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
    minExpected = Math.max(componentStrokeCounts.length, Math.ceil(totalStdStrokes * 0.6));
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
  const loopChars = ['០', 'ំ', 'ះ', 'ៈ', '៎', '៏', '៌', '៍', 'ឹ', 'ឺ', 'ូ'];
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
    if (ratio > 8.0 || ratio < 0.125) {
      shapeScore = Math.max(20, shapeScore - 30);
      errors.push('Nét vẽ bị lệch tỷ lệ quá mức');
      issues.push({
        type: 'aspect_ratio',
        detail: 'Con hãy viết chữ ghép cân đối và đẹp hơn nhé!',
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

  // Jaggedness check
  if (avgSmoothCos < 0.45 || totalNegatives > userStrokes.length * 4) {
    errors.push('Nét vẽ bị run hoặc quá ngoằn ngoèo');
    issues.push({
      type: 'smoothness',
      detail: 'Con hãy viết chậm lại và vẽ nét thật mượt mà nhé! ✏️',
    });
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
    const priority = { loop: 0, incomplete: 1, size: 2, distribution: 3, smoothness: 4, aspect_ratio: 5 };
    issues.sort((a, b) => (priority[a.type] ?? 4) - (priority[b.type] ?? 4));
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
    },
  };
}

module.exports = {
  analyzeCompoundStrokes,
};
