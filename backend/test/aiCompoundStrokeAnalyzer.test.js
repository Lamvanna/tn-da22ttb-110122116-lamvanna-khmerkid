'use strict';

const { analyzeCompoundStrokes } = require('../src/services/aiCompoundStrokeAnalyzer');

describe('AI Compound Stroke Analyzer Tests', () => {
  test('Empty strokes should return failed analysis with 0 score', () => {
    const result = analyzeCompoundStrokes({ userStrokes: [], character: 'កា' });
    expect(result.success).toBe(false);
    expect(result.similarityScore).toBe(0);
    expect(result.feedback).toContain('Con chưa viết gì cả');
  });

  test('Valid strokes should return passing score', () => {
    // 2 strokes representing "កា", drawn smoothly and spread out
    const stroke1 = [
      { x: 10, y: 10, t: 0 },
      { x: 20, y: 12, t: 16 },
      { x: 30, y: 15, t: 32 },
      { x: 40, y: 20, t: 48 },
    ];
    const stroke2 = [
      { x: 70, y: 10, t: 100 },
      { x: 75, y: 25, t: 116 },
      { x: 80, y: 40, t: 132 },
      { x: 85, y: 55, t: 148 },
    ];

    const result = analyzeCompoundStrokes({ userStrokes: [stroke1, stroke2], character: 'កា' });
    expect(result.success).toBe(true);
    expect(result.similarityScore).toBeGreaterThanOrEqual(65);
    expect(result.strokeCountScore).toBe(100);
  });

  test('Too few strokes should penalize stroke count score', () => {
    // 1 stroke for character length 2
    const stroke = [
      { x: 10, y: 10, t: 0 },
      { x: 90, y: 90, t: 100 },
    ];

    const result = analyzeCompoundStrokes({ userStrokes: [stroke], character: 'កា' });
    expect(result.strokeCountScore).toBeLessThan(100);
  });

  test('Tiny strokes should trigger size issues and low score', () => {
    // A tiny wiggle
    const stroke1 = [
      { x: 10, y: 10, t: 0 },
      { x: 11, y: 11, t: 16 },
    ];
    const stroke2 = [
      { x: 12, y: 12, t: 32 },
      { x: 13, y: 13, t: 48 },
    ];

    const result = analyzeCompoundStrokes({ userStrokes: [stroke1, stroke2], character: 'កា' });
    expect(result.success).toBe(false);
    expect(result.feedback).toContain('viết chữ to và rõ hơn');
  });

  test('Erratic / jagged wiggles should penalize smoothness', () => {
    // Zig-zag stroke (180 degree direction changes)
    const jaggedStroke = [
      { x: 10, y: 10, t: 0 },
      { x: 20, y: 10, t: 16 },
      { x: 10, y: 10, t: 32 },
      { x: 20, y: 10, t: 48 },
      { x: 10, y: 10, t: 64 },
    ];

    const result = analyzeCompoundStrokes({ userStrokes: [jaggedStroke, jaggedStroke], character: 'កា' });
    expect(result.directionScore).toBeLessThan(50);
  });

  test('Drawing circles / loops when not allowed should result in a failure', () => {
    // Generate two circles: outer and inner
    const outerCircle = [];
    const innerCircle = [];
    const steps = 30;
    for (let i = 0; i <= steps; i++) {
      const theta = (i / steps) * 2 * Math.PI;
      outerCircle.push({
        x: 50 + 40 * Math.cos(theta),
        y: 50 + 40 * Math.sin(theta),
        t: i * 10,
      });
      innerCircle.push({
        x: 50 + 20 * Math.cos(theta),
        y: 50 + 20 * Math.sin(theta),
        t: 300 + i * 10,
      });
    }

    const result = analyzeCompoundStrokes({
      userStrokes: [outerCircle, innerCircle],
      character: 'កា',
    });

    expect(result.success).toBe(false);
    expect(result.similarityScore).toBeLessThan(50);
    expect(result.feedback).toContain('không nên vẽ hình tròn hoặc vòng lặp');
  });

  test('Drawing only parts of a compound character (incomplete) should fail', () => {
    // User drew 2 strokes for 'កា', but standard is 5, component stroke counts are [3, 2]
    const stroke1 = [
      { x: 10, y: 10, t: 0 },
      { x: 20, y: 20, t: 16 },
    ];
    const stroke2 = [
      { x: 30, y: 30, t: 32 },
      { x: 40, y: 40, t: 48 },
    ];

    const result = analyzeCompoundStrokes({
      userStrokes: [stroke1, stroke2],
      character: 'កា',
      componentStrokeCounts: [3, 2], // ក is 3, ា is 2
    });

    expect(result.success).toBe(false);
    expect(result.similarityScore).toBeLessThan(50);
    expect(result.feedback).toContain('Con viết chưa xong chữ ghép này');
  });
});

