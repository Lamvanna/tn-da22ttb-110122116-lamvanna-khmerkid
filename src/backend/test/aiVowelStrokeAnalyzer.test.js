/**
 * ============================================================================
 * Jest Unit Tests — aiVowelStrokeAnalyzer
 * ============================================================================
 * Tests the dedicated vowel stroke analyzer.
 */

'use strict';

const { analyzeVowelStrokes } = require('../src/services/aiVowelStrokeAnalyzer');

describe('AI Vowel Stroke Analyzer Unit Tests', () => {

  test('Should return success: true with high similarity score for identical strokes', () => {
    // Vowel ា (aa) - single vertical line
    const stdStrokes = [
      [
        { x: 50, y: 20, t: 0 },
        { x: 50, y: 50, t: 80 },
        { x: 50, y: 80, t: 160 },
      ]
    ];

    const userStrokes = [
      [
        { x: 50, y: 20, t: 0 },
        { x: 50, y: 50, t: 80 },
        { x: 50, y: 80, t: 160 },
      ]
    ];

    const result = analyzeVowelStrokes({
      userStrokes,
      standardStrokes: stdStrokes,
      character: 'ា',
    });

    expect(result.success).toBe(true);
    expect(result.similarityScore).toBe(100);
    expect(result.shapeScore).toBe(100);
    expect(result.directionScore).toBe(100);
    expect(result.strokeCountScore).toBe(100);
  });

  test('Should handle small noise / variation gracefully and give high score', () => {
    const stdStrokes = [
      [
        { x: 50, y: 20, t: 0 },
        { x: 50, y: 80, t: 160 },
      ]
    ];

    // Slightly shifted and wobbly line
    const userStrokes = [
      [
        { x: 51, y: 21, t: 0 },
        { x: 49, y: 50, t: 80 },
        { x: 52, y: 79, t: 160 },
      ]
    ];

    const result = analyzeVowelStrokes({
      userStrokes,
      standardStrokes: stdStrokes,
      character: 'ា',
    });

    expect(result.success).toBe(true);
    expect(result.similarityScore).toBeGreaterThanOrEqual(85);
  });

  test('Should detect reversed stroke direction and give warning', () => {
    const stdStrokes = [
      [
        { x: 50, y: 20, t: 0 },
        { x: 50, y: 80, t: 160 },
      ]
    ];

    // User drew bottom-to-top instead of top-to-bottom
    const userStrokes = [
      [
        { x: 50, y: 80, t: 0 },
        { x: 50, y: 20, t: 160 },
      ]
    ];

    const result = analyzeVowelStrokes({
      userStrokes,
      standardStrokes: stdStrokes,
      character: 'ា',
    });

    expect(result.success).toBe(true);
    expect(result.directionScore).toBeLessThan(40);
    expect(result.errors.length).toBeGreaterThan(0);
    expect(result.errors[0]).toContain('ngược rồi');
  });

  test('Should handle stroke count mismatch penalty', () => {
    const stdStrokes = [
      [
        { x: 50, y: 20, t: 0 },
        { x: 50, y: 80, t: 160 },
      ]
    ];

    // User drew 2 strokes instead of 1
    const userStrokes = [
      [{ x: 50, y: 20, t: 0 }, { x: 50, y: 40, t: 50 }],
      [{ x: 50, y: 50, t: 60 }, { x: 50, y: 80, t: 120 }],
    ];

    const result = analyzeVowelStrokes({
      userStrokes,
      standardStrokes: stdStrokes,
      character: 'ា',
    });

    expect(result.success).toBe(true);
    expect(result.strokeCountScore).toBeLessThan(100);
  });

  test('Should prevent over-scaling of small marks', () => {
    // A tiny dot/accent mark (ិ)
    const stdStrokes = [
      [
        { x: 48, y: 12, t: 0 },
        { x: 52, y: 12, t: 100 },
      ]
    ];

    const userStrokes = [
      [
        { x: 48, y: 12, t: 0 },
        { x: 52, y: 12, t: 100 },
      ]
    ];

    const result = analyzeVowelStrokes({
      userStrokes,
      standardStrokes: stdStrokes,
      character: 'ិ',
    });

    expect(result.success).toBe(true);
    expect(result.similarityScore).toBe(100);
  });

  test('Should reject scribbles and give a low similarity score', () => {
    const stdStrokes = [
      [
        { x: 40, y: 35, t: 0 },
        { x: 44, y: 28, t: 20 },
        { x: 50, y: 23, t: 40 },
        { x: 56, y: 20, t: 60 },
        { x: 62, y: 23, t: 80 },
        { x: 65, y: 30, t: 100 },
        { x: 65, y: 45, t: 120 },
        { x: 65, y: 62, t: 140 },
        { x: 65, y: 80, t: 160 },
      ]
    ];

    // A scribble that loops/zigzag heavily in the box
    const scribble = [];
    let t = 0;
    for (let loop = 0; loop < 5; loop++) {
      scribble.push({ x: 20, y: 20, t: t++ });
      scribble.push({ x: 80, y: 20, t: t++ });
      scribble.push({ x: 80, y: 80, t: t++ });
      scribble.push({ x: 20, y: 80, t: t++ });
    }

    const result = analyzeVowelStrokes({
      userStrokes: [scribble],
      standardStrokes: stdStrokes,
      character: 'ា',
    });

    console.log('Scribble similarityScore:', result.similarityScore);
    console.log('Scribble details:', JSON.stringify(result.details, null, 2));
    expect(result.similarityScore).toBeLessThan(50);
  });

  test('Should reject wobbly/zigzag stroke drawn on srak a and give mượt mà warning', () => {
    const stdStrokes = [
      [
        { x: 40, y: 35, t: 0 },
        { x: 44, y: 28, t: 20 },
        { x: 50, y: 23, t: 40 },
        { x: 56, y: 20, t: 60 },
        { x: 62, y: 23, t: 80 },
        { x: 65, y: 30, t: 100 },
        { x: 65, y: 45, t: 120 },
        { x: 65, y: 62, t: 140 },
        { x: 65, y: 80, t: 160 },
      ]
    ];

    const userStrokes = [
      [
        { x: 50, y: 38, t: 0 },
        { x: 58, y: 32, t: 10 },
        { x: 65, y: 28, t: 20 },
        { x: 60, y: 30, t: 30 },
        { x: 67, y: 35, t: 40 },
        { x: 74, y: 38, t: 50 },
        { x: 67, y: 43, t: 60 },
        { x: 64, y: 50, t: 70 },
        { x: 66, y: 58, t: 80 },
        { x: 60, y: 65, t: 90 },
        { x: 67, y: 72, t: 100 },
        { x: 62, y: 78, t: 110 },
        { x: 65, y: 85, t: 120 },
      ]
    ];

    const result = analyzeVowelStrokes({
      userStrokes,
      standardStrokes: stdStrokes,
      character: 'ា',
    });

    expect(result.success).toBe(true);
    expect(result.similarityScore).toBeLessThan(65);
    expect(result.errors[0]).toContain('mượt mà');
  });

  test('Should reject srak ii (2 strokes) drawn on srak i (1 stroke expected)', () => {
    // Standard srak i (1 stroke: dome)
    const stdStrokes = [
      [
        { x: 60, y: 22, t: 0 },
        { x: 40, y: 22, t: 60 },
        { x: 50, y: 10, t: 120 },
        { x: 60, y: 22, t: 180 },
      ]
    ];

    // User drew srak ii (2 strokes: dome + tick)
    const userStrokes = [
      [
        { x: 60, y: 22, t: 0 },
        { x: 40, y: 22, t: 60 },
        { x: 50, y: 10, t: 120 },
        { x: 60, y: 22, t: 180 },
      ],
      [
        { x: 50, y: 13, t: 0 },
        { x: 50, y: 21, t: 60 },
      ]
    ];

    const result = analyzeVowelStrokes({
      userStrokes,
      standardStrokes: stdStrokes,
      character: 'ិ',
    });

    console.log('2 strokes on 1 stroke expected score:', result.similarityScore);
    expect(result.similarityScore).toBeLessThan(70);
  });

  test('Should reject srak i (1 stroke) drawn on srak ii (2 strokes expected)', () => {
    // Standard srak ii (2 strokes: dome + tick)
    const stdStrokes = [
      [
        { x: 60, y: 22, t: 0 },
        { x: 40, y: 22, t: 60 },
        { x: 50, y: 10, t: 120 },
        { x: 60, y: 22, t: 180 },
      ],
      [
        { x: 50, y: 13, t: 0 },
        { x: 50, y: 21, t: 60 },
      ]
    ];

    // User drew srak i (1 stroke: dome)
    const userStrokes = [
      [
        { x: 60, y: 22, t: 0 },
        { x: 40, y: 22, t: 60 },
        { x: 50, y: 10, t: 120 },
        { x: 60, y: 22, t: 180 },
      ]
    ];

    const result = analyzeVowelStrokes({
      userStrokes,
      standardStrokes: stdStrokes,
      character: 'ី',
    });

    console.log('1 stroke on 2 strokes expected score:', result.similarityScore);
    expect(result.similarityScore).toBeLessThan(70);
  });

  test('Should reject srak ue (dome + circle in 1 stroke) drawn on srak i (1 stroke expected)', () => {
    // Standard srak i (1 stroke: dome)
    const stdStrokes = [
      [
        { x: 60, y: 22, t: 0 },
        { x: 40, y: 22, t: 60 },
        { x: 50, y: 10, t: 120 },
        { x: 60, y: 22, t: 180 },
      ]
    ];

    // User drew srak ue in 1 continuous stroke (dome + circle)
    const userStrokes = [
      [
        { x: 60, y: 22, t: 0 },
        { x: 40, y: 22, t: 60 },
        { x: 50, y: 10, t: 120 },
        { x: 60, y: 22, t: 180 },
        { x: 60, y: 16, t: 200 },
        { x: 55, y: 10, t: 220 },
        { x: 50, y: 16, t: 240 },
        { x: 55, y: 22, t: 260 },
        { x: 60, y: 16, t: 280 },
      ]
    ];

    const result = analyzeVowelStrokes({
      userStrokes,
      standardStrokes: stdStrokes,
      character: 'ិ',
    });

    console.log('Single-stroke srak ue on srak i expected score:', result.similarityScore);
    expect(result.similarityScore).toBeLessThan(65);
  });
});


