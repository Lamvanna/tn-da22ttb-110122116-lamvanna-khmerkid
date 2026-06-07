/**
 * ============================================================================
 * Jest Unit Tests — aiStrokeAnalyzer
 * ============================================================================
 * Tests the core geometric comparison algorithms, DTW, direction vectors,
 * resampling, and full integrated feedback reporting.
 */

'use strict';

const { analyzeStrokes, _internals } = require('../src/services/aiStrokeAnalyzer');
const {
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
} = _internals;

describe('AI Stroke Analyzer Unit Tests', () => {

  describe('1. Geometry Utilities', () => {
    test('dist computes correct 2D distance', () => {
      expect(dist({ x: 0, y: 0 }, { x: 3, y: 4 })).toBe(5);
    });

    test('pathLength computes total distance of connected points', () => {
      const points = [
        { x: 0, y: 0 },
        { x: 3, y: 0 },
        { x: 3, y: 4 }
      ];
      expect(pathLength(points)).toBe(7);
    });

    test('centroid calculates geometric center correctly', () => {
      const points = [
        { x: 0, y: 0 },
        { x: 10, y: 0 },
        { x: 10, y: 10 },
        { x: 0, y: 10 }
      ];
      expect(centroid(points)).toEqual({ x: 5, y: 5 });
    });

    test('boundingBox returns correct bounds and dimensions', () => {
      const points = [
        { x: 5, y: -2 },
        { x: 12, y: 8 },
        { x: 3, y: 4 }
      ];
      expect(boundingBox(points)).toEqual({
        minX: 3,
        minY: -2,
        maxX: 12,
        maxY: 8,
        width: 9,
        height: 10,
      });
    });
  });

  describe('2. Preprocessing', () => {
    test('resampleStroke converts stroke to exactly N points', () => {
      const stroke = [
        { x: 0, y: 0, t: 100 },
        { x: 100, y: 0, t: 200 }
      ];
      const resampled = resampleStroke(stroke, 32);
      expect(resampled.length).toBe(32);
      expect(resampled[0].x).toBe(0);
      expect(resampled[31].x).toBeCloseTo(100, 5);
      // Verify equal interval distribution
      const step = 100 / 31;
      for (let i = 0; i < 32; i++) {
        expect(resampled[i].x).toBeCloseTo(i * step, 5);
        expect(resampled[i].y).toBe(0);
        expect(Math.abs(resampled[i].t - (100 + i * (100 / 31)))).toBeLessThanOrEqual(5);
      }
    });

    test('resampleStroke handles single dot degenerate case', () => {
      const dot = [{ x: 50, y: 50, t: 500 }];
      const resampled = resampleStroke(dot, 32);
      expect(resampled.length).toBe(32);
      resampled.forEach(p => {
        expect(p).toEqual({ x: 50, y: 50, t: 500 });
      });
    });

    test('normalizeStrokes fits drawing into NORM_SIZE bounds while preserving aspect ratio', () => {
      // Draw a box: 200 to 300 (W=100, H=50)
      const strokes = [
        [
          { x: 200, y: 100 },
          { x: 300, y: 100 }
        ],
        [
          { x: 300, y: 100 },
          { x: 300, y: 150 }
        ]
      ];
      const normalized = normalizeStrokes(strokes);
      const flatNormalized = normalized.flat();
      const bounds = boundingBox(flatNormalized);

      // Maximum dimension (width = 100) should scale to NORM_SIZE (100)
      expect(bounds.width).toBeCloseTo(100, 5);
      // Aspect ratio must be preserved: height (50) scales to 50
      expect(bounds.height).toBeCloseTo(50, 5);
      // Combined box is centered: offsetX should center height
      expect(bounds.minX).toBeCloseTo(0, 5);
      expect(bounds.minY).toBeCloseTo(25, 5); // offset Y = (100 - 50)/2 = 25
    });
  });

  describe('3. Dynamic Time Warping (DTW)', () => {
    test('dtwDistance of identical sequences is 0', () => {
      const s1 = [{ x: 0, y: 0 }, { x: 5, y: 5 }, { x: 10, y: 10 }];
      expect(dtwDistance(s1, s1)).toBe(0);
      expect(dtwToSimilarity(0)).toBe(100);
    });

    test('dtwDistance matches slightly warped paths with low cost', () => {
      // s1 is linear: (0,0) -> (10,10)
      const s1 = [{ x: 0, y: 0 }, { x: 5, y: 5 }, { x: 10, y: 10 }];
      // s2 has duplicate points (warped in time)
      const s2 = [{ x: 0, y: 0 }, { x: 0, y: 0 }, { x: 5, y: 5 }, { x: 10, y: 10 }, { x: 10, y: 10 }];
      expect(dtwDistance(s1, s2)).toBe(0);
      expect(dtwToSimilarity(dtwDistance(s1, s2))).toBe(100);
    });

    test('dtwDistance is large for dissimilar paths', () => {
      const s1 = [{ x: 0, y: 0 }, { x: 5, y: 0 }, { x: 10, y: 0 }];
      const s2 = [{ x: 0, y: 50 }, { x: 5, y: 50 }, { x: 10, y: 50 }];
      const dist = dtwDistance(s1, s2);
      expect(dist).toBe(50);
      expect(dtwToSimilarity(dist)).toBeLessThan(60);
    });
  });

  describe('4. Directional Vectors & Cosine Similarity', () => {
    test('cosineSimilarity behaves correctly for parallel, perpendicular, and reversed vectors', () => {
      const vRight = { dx: 1, dy: 0 };
      const vLeft = { dx: -1, dy: 0 };
      const vUp = { dx: 0, dy: -1 };

      expect(cosineSimilarity(vRight, vRight)).toBeCloseTo(1, 5);
      expect(cosineSimilarity(vRight, vLeft)).toBeCloseTo(-1, 5);
      expect(cosineSimilarity(vRight, vUp)).toBeCloseTo(0, 5);
    });

    test('dominantDirection detects correct vector from points order', () => {
      // Top-to-bottom line
      const stroke = [
        { x: 50, y: 10, t: 100 },
        { x: 50, y: 90, t: 200 }
      ];
      const dir = dominantDirection(stroke);
      expect(dir.dx).toBeCloseTo(0, 5);
      expect(dir.dy).toBeCloseTo(1, 5); // Downward unit vector (dy > 0)
    });

    test('segmentDirectionAnalysis reports reversed segments for opposing paths', () => {
      const strokeStd = [
        { x: 0, y: 0 },
        { x: 50, y: 0 },
        { x: 100, y: 0 }
      ];
      const strokeUserReversed = [
        { x: 100, y: 0 },
        { x: 50, y: 0 },
        { x: 0, y: 0 }
      ];
      const resStd = resampleStroke(strokeStd, 32);
      const resUser = resampleStroke(strokeUserReversed, 32);

      const analysis = segmentDirectionAnalysis(resUser, resStd);
      expect(analysis.avgCosine).toBeCloseTo(-1, 5);
      expect(analysis.reversedSegments).toBe(31);
      expect(directionToScore(analysis.avgCosine)).toBe(0);
    });
  });

  describe('5. Stroke Pairing (matchStrokes)', () => {
    test('matchStrokes pairs user strokes to closest standard strokes correctly', () => {
      // Two horizontal lines: line 1 at y=20, line 2 at y=80
      const std1 = [{ x: 10, y: 20 }, { x: 90, y: 20 }];
      const std2 = [{ x: 10, y: 80 }, { x: 90, y: 80 }];

      // User drew line 2 first, then line 1
      const user1 = [{ x: 10, y: 80 }, { x: 90, y: 80 }]; // matches std2
      const user2 = [{ x: 10, y: 20 }, { x: 90, y: 20 }]; // matches std1

      const pairs = matchStrokes([user1, user2], [std1, std2]);
      expect(pairs.length).toBe(2);

      // Verify correct pairing mapping
      const pairForStd1 = pairs.find(p => p.stdIdx === 0);
      const pairForStd2 = pairs.find(p => p.stdIdx === 1);

      expect(pairForStd1.userIdx).toBe(1); // std1 matches user2
      expect(pairForStd2.userIdx).toBe(0); // std2 matches user1
    });
  });

  describe('6. Integrated analyzeStrokes Function', () => {
    // A standard two-stroke character (e.g. cross shape)
    const standardStrokes = [
      // Stroke 1: horizontal left-to-right
      [
        { x: 10, y: 50, t: 0 },
        { x: 90, y: 50, t: 100 }
      ],
      // Stroke 2: vertical top-to-bottom
      [
        { x: 50, y: 10, t: 200 },
        { x: 50, y: 90, t: 300 }
      ]
    ];

    test('returns high score and positive feedback for ideal drawing matching standard', () => {
      const userStrokes = [
        [
          { x: 10, y: 50, t: 0 },
          { x: 90, y: 50, t: 100 }
        ],
        [
          { x: 50, y: 10, t: 200 },
          { x: 50, y: 90, t: 300 }
        ]
      ];

      const result = analyzeStrokes({ userStrokes, standardStrokes, character: 'ក' });
      expect(result.success).toBe(true);
      expect(result.similarityScore).toBeGreaterThanOrEqual(90);
      expect(result.strokeCountScore).toBe(100);
      expect(result.errorStrokeIndex).toBe(-1);
      expect(result.feedback).toContain('Tuyệt vời');
    });

    test('flags reversed stroke and gives directional feedback', () => {
      const userStrokes = [
        // Stroke 1: horizontal left-to-right (correct)
        [
          { x: 10, y: 50, t: 0 },
          { x: 90, y: 50, t: 100 }
        ],
        // Stroke 2: vertical bottom-to-top (reversed, should be top-to-bottom)
        [
          { x: 50, y: 90, t: 200 },
          { x: 50, y: 10, t: 300 }
        ]
      ];

      const result = analyzeStrokes({ userStrokes, standardStrokes, character: 'ក' });
      expect(result.success).toBe(true);
      expect(result.directionScore).toBeLessThan(70);
      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.errorStrokeIndex).toBe(1); // Standard stroke 2 (index 1) is reversed
      expect(result.feedback).toContain('ngược hướng');
      expect(result.feedback).toContain('kéo từ trên xuống');
    });

    test('does not penalize missing strokes if user draws fewer strokes than expected', () => {
      const userStrokes = [
        // Only horizontal stroke drawn
        [
          { x: 10, y: 50, t: 0 },
          { x: 90, y: 50, t: 100 }
        ]
      ];

      const result = analyzeStrokes({ userStrokes, standardStrokes, character: 'ក' });
      expect(result.success).toBe(true);
      expect(result.strokeCountScore).toBe(100);
      expect(result.errors.length).toBe(0);
      expect(result.feedback).not.toContain('thiếu');
    });

    test('does not penalize extra strokes if user draws more strokes than expected', () => {
      const userStrokes = [
        ...standardStrokes,
        // Extra third stroke
        [
          { x: 10, y: 10, t: 400 },
          { x: 20, y: 20, t: 500 }
        ]
      ];

      const result = analyzeStrokes({ userStrokes, standardStrokes, character: 'ក' });
      expect(result.success).toBe(true);
      expect(result.strokeCountScore).toBe(100);
      expect(result.errorStrokeIndex).toBe(-1);
      expect(result.feedback).not.toContain('thừa');
    });

    test('gracefully handles empty or null input', () => {
      const resultEmpty = analyzeStrokes({ userStrokes: [], standardStrokes });
      expect(resultEmpty.success).toBe(false);
      expect(resultEmpty.feedback).toContain('Con chưa viết gì');

      const resultNull = analyzeStrokes({ userStrokes: null, standardStrokes });
      expect(resultNull.success).toBe(false);
    });

    test('supports writing a 2-stroke standard character in 1 single continuous stroke', () => {
      // Standard has 2 strokes: wavy cap + arch
      // User draws the whole shape in 1 stroke continuously
      const userStrokes = [
        [
          // Stroke 1 & 2 merged
          { x: 10, y: 50, t: 0 },
          { x: 90, y: 50, t: 100 },
          { x: 50, y: 10, t: 200 },
          { x: 50, y: 90, t: 300 }
        ]
      ];

      const result = analyzeStrokes({ userStrokes, standardStrokes, character: 'ក' });
      expect(result.success).toBe(true);
      expect(result.similarityScore).toBeGreaterThanOrEqual(75);
      expect(result.feedback).toContain('Tuyệt vời' || 'Khá tốt');
    });

    test('supports writing a 1-stroke standard character in 2 separate strokes (paused drawing)', () => {
      const standard1Stroke = [
        [
          { x: 10, y: 10, t: 0 },
          { x: 50, y: 50, t: 100 },
          { x: 90, y: 90, t: 200 }
        ]
      ];
      // User drew the same line but nhấc bút halfway (2 strokes)
      const userStrokes = [
        [
          { x: 10, y: 10, t: 0 },
          { x: 50, y: 50, t: 100 }
        ],
        [
          { x: 50, y: 50, t: 150 },
          { x: 90, y: 90, t: 250 }
        ]
      ];

      const result = analyzeStrokes({ userStrokes, standardStrokes: standard1Stroke, character: 'ន' });
      expect(result.success).toBe(true);
      expect(result.similarityScore).toBeGreaterThanOrEqual(80);
    });
  });
});
