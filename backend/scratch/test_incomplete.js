'use strict';

const { analyzeCompoundStrokes } = require('../src/services/aiCompoundStrokeAnalyzer');

// Simulated 2-stroke drawing for "កា" (only wrote 'ក')
const stroke1 = [
  { x: 10, y: 10, t: 0 },
  { x: 20, y: 12, t: 16 },
  { x: 30, y: 15, t: 32 },
  { x: 40, y: 20, t: 48 },
];
const stroke2 = [
  { x: 40, y: 20, t: 100 },
  { x: 50, y: 10, t: 116 },
  { x: 60, y: 20, t: 132 },
];

const result = analyzeCompoundStrokes({
  userStrokes: [stroke1, stroke2],
  character: 'កា',
  componentStrokeCounts: [3, 2], // 'ក' is 3 strokes, 'ា' is 2 strokes
});

console.log('Result:', JSON.stringify(result, null, 2));
