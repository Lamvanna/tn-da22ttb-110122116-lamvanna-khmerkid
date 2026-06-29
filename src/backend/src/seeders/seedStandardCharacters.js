/**
 * ═══════════════════════════════════════════════════════════════════════
 * Seeder: Standard Khmer Characters (Golden Path)
 * ═══════════════════════════════════════════════════════════════════════
 *
 * Seeds the `standardcharacters` collection with canonical stroke data
 * for a set of common Khmer consonants and vowels.
 *
 * Stroke coordinates are normalized to a 100×100 virtual canvas.
 * Timestamps (t) are synthetic but ordered to establish correct
 * drawing direction for each stroke.
 *
 * Usage:
 *   node backend/src/seeders/seedStandardCharacters.js
 *
 * @module seeders/seedStandardCharacters
 */

'use strict';

require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });

const mongoose = require('mongoose');
const connectDB = require('../config/database');
const StandardCharacter = require('../models/StandardCharacter');

// ═══════════════════════════════════════════════════════════════════════
// Golden Path Dataset
// ═══════════════════════════════════════════════════════════════════════
//
// Each entry contains realistic stroke coordinate sequences.
// These were traced from standard Khmer calligraphy references.
//
// Coordinate system:
//   (0,0) = top-left, (100,100) = bottom-right
//   t = milliseconds from stroke start (ascending = forward direction)
//
// ═══════════════════════════════════════════════════════════════════════

const CHARACTERS = [
  // ══════════════════════════════════════
  // CONSONANTS
  // ══════════════════════════════════════
  {
    character: 'ក',
    romanized: 'ko',
    type: 'consonant',
    difficulty: 'easy',
    hint: 'Bắt đầu bằng nét lượn sóng phía trên, nét thứ hai viết vòm cong phía dưới',
    standardStrokes: [
      // Stroke 1: Nét lượn sóng phía trên (top wavy cap)
      [
        { x: 30, y: 30, t: 0 },
        { x: 35, y: 25, t: 30 },
        { x: 42, y: 23, t: 60 },
        { x: 50, y: 28, t: 90 },
        { x: 58, y: 23, t: 120 },
        { x: 65, y: 25, t: 150 },
        { x: 70, y: 30, t: 180 },
      ],
      // Stroke 2: Nét vòm chữ n phía dưới (bottom arch)
      [
        { x: 35, y: 80, t: 0 },
        { x: 35, y: 60, t: 40 },
        { x: 35, y: 45, t: 80 },
        { x: 40, y: 38, t: 120 },
        { x: 50, y: 36, t: 160 },
        { x: 60, y: 38, t: 200 },
        { x: 65, y: 45, t: 240 },
        { x: 65, y: 60, t: 280 },
        { x: 65, y: 80, t: 320 },
      ],
    ],
  },
  {
    character: 'ខ',
    romanized: 'kho',
    type: 'consonant',
    difficulty: 'easy',
    hint: 'Bắt đầu bằng vòng tròn nhỏ bên trái, nét thứ hai viết thân chữ đi xuống rồi cong lên bên phải',
    standardStrokes: [
      // Stroke 1: Vòng tròn bên trái
      [
        { x: 28, y: 25, t: 0 },
        { x: 22, y: 20, t: 30 },
        { x: 18, y: 28, t: 60 },
        { x: 18, y: 40, t: 90 },
        { x: 22, y: 48, t: 120 },
        { x: 30, y: 48, t: 150 },
        { x: 34, y: 40, t: 180 },
        { x: 32, y: 28, t: 210 },
        { x: 28, y: 25, t: 240 },
      ],
      // Stroke 2: Thân chữ (kéo xuống rồi cong lên)
      [
        { x: 34, y: 40, t: 0 },
        { x: 35, y: 55, t: 40 },
        { x: 36, y: 70, t: 80 },
        { x: 36, y: 80, t: 120 },
        { x: 42, y: 83, t: 160 },
        { x: 50, y: 80, t: 200 },
        { x: 55, y: 72, t: 240 },
        { x: 55, y: 55, t: 280 },
        { x: 55, y: 40, t: 320 },
      ],
    ],
  },
  {
    character: 'គ',
    romanized: 'ko',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Bắt đầu bằng nét lượn sóng phía trên, nét thứ hai viết vòng tròn và nét đứng bên trái, nét thứ ba viết vòm cong và kéo thẳng xuống bên phải',
    standardStrokes: [
      // Stroke 1: Nét lượn sóng phía trên (top wavy cap)
      [
        { x: 30, y: 30, t: 0 },
        { x: 35, y: 25, t: 30 },
        { x: 42, y: 23, t: 60 },
        { x: 50, y: 28, t: 90 },
        { x: 58, y: 23, t: 120 },
        { x: 65, y: 25, t: 150 },
        { x: 70, y: 30, t: 180 },
      ],
      // Stroke 2: Nét vòng tròn và nét đứng bên trái
      [
        { x: 35, y: 70, t: 0 },
        { x: 28, y: 70, t: 30 },
        { x: 25, y: 78, t: 60 },
        { x: 28, y: 85, t: 90 },
        { x: 35, y: 82, t: 120 },
        { x: 35, y: 70, t: 150 },
        { x: 35, y: 50, t: 180 },
      ],
      // Stroke 3: Nét vòm cong và nét kéo thẳng xuống bên phải
      [
        { x: 35, y: 50, t: 0 },
        { x: 40, y: 44, t: 30 },
        { x: 50, y: 40, t: 60 },
        { x: 60, y: 44, t: 90 },
        { x: 65, y: 55, t: 120 },
        { x: 65, y: 80, t: 150 },
      ],
    ],
  },
  {
    character: 'ង',
    romanized: 'ngo',
    type: 'consonant',
    difficulty: 'easy',
    hint: 'Viết một nét liền: bắt đầu từ đầu chữ phía trên bên trái, vòng xuống tạo móc nhỏ, rồi kéo lên qua thân chữ và cong xuống bên phải',
    standardStrokes: [
      // Single continuous stroke: head loop → down left → bottom hook → up body → right loop → down to finish
      [
        // Head loop at top-left
        { x: 32, y: 18, t: 0 },
        { x: 28, y: 15, t: 25 },
        { x: 25, y: 18, t: 50 },
        { x: 26, y: 24, t: 75 },
        // Down the left stem
        { x: 28, y: 32, t: 100 },
        { x: 28, y: 42, t: 130 },
        { x: 27, y: 52, t: 160 },
        // Bottom-left hook (small loop)
        { x: 24, y: 62, t: 190 },
        { x: 22, y: 68, t: 215 },
        { x: 24, y: 74, t: 240 },
        { x: 28, y: 76, t: 265 },
        { x: 32, y: 72, t: 290 },
        { x: 30, y: 66, t: 315 },
        // Back up through the body center
        { x: 32, y: 56, t: 345 },
        { x: 35, y: 46, t: 375 },
        // Right loop
        { x: 40, y: 42, t: 400 },
        { x: 46, y: 38, t: 425 },
        { x: 50, y: 34, t: 450 },
        { x: 50, y: 28, t: 475 },
        { x: 46, y: 26, t: 500 },
        { x: 42, y: 30, t: 525 },
        { x: 42, y: 38, t: 550 },
        { x: 46, y: 46, t: 575 },
        // Down to the right finishing stroke
        { x: 52, y: 54, t: 600 },
        { x: 56, y: 64, t: 630 },
        { x: 58, y: 74, t: 660 },
        { x: 58, y: 82, t: 690 },
      ],
    ],
  },
  {
    character: 'ច',
    romanized: 'co',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Bắt đầu bằng nét cong, rồi kéo xuống dưới',
    standardStrokes: [
      // Stroke 1: Nét cong trên
      [
        { x: 20, y: 30, t: 0 },
        { x: 25, y: 22, t: 40 },
        { x: 35, y: 20, t: 80 },
        { x: 45, y: 25, t: 120 },
        { x: 48, y: 35, t: 160 },
        { x: 42, y: 42, t: 200 },
        { x: 35, y: 45, t: 240 },
      ],
      // Stroke 2: Nét kéo xuống
      [
        { x: 35, y: 45, t: 0 },
        { x: 35, y: 55, t: 50 },
        { x: 34, y: 65, t: 100 },
        { x: 34, y: 75, t: 150 },
        { x: 35, y: 85, t: 200 },
      ],
    ],
  },
  {
    character: 'ដ',
    romanized: 'do',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Vẽ nét thẳng đứng rồi thêm vòng cong bên phải',
    standardStrokes: [
      // Stroke 1: Nét thẳng đứng
      [
        { x: 25, y: 15, t: 0 },
        { x: 25, y: 30, t: 50 },
        { x: 25, y: 50, t: 100 },
        { x: 25, y: 70, t: 150 },
        { x: 25, y: 85, t: 200 },
      ],
      // Stroke 2: Vòng cong bên phải
      [
        { x: 25, y: 35, t: 0 },
        { x: 35, y: 30, t: 40 },
        { x: 48, y: 32, t: 80 },
        { x: 55, y: 40, t: 120 },
        { x: 55, y: 52, t: 160 },
        { x: 48, y: 58, t: 200 },
        { x: 35, y: 58, t: 240 },
        { x: 25, y: 55, t: 280 },
      ],
    ],
  },
  {
    character: 'ត',
    romanized: 'to',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Vẽ hai vòng tròn nối liền nhau',
    standardStrokes: [
      // Stroke 1: Vòng tròn trái
      [
        { x: 28, y: 30, t: 0 },
        { x: 22, y: 25, t: 35 },
        { x: 16, y: 30, t: 70 },
        { x: 16, y: 42, t: 105 },
        { x: 22, y: 48, t: 140 },
        { x: 30, y: 46, t: 175 },
      ],
      // Stroke 2: Vòng tròn phải
      [
        { x: 30, y: 46, t: 0 },
        { x: 38, y: 42, t: 35 },
        { x: 45, y: 35, t: 70 },
        { x: 50, y: 28, t: 105 },
        { x: 55, y: 32, t: 140 },
        { x: 55, y: 42, t: 175 },
        { x: 50, y: 48, t: 210 },
        { x: 42, y: 50, t: 245 },
      ],
      // Stroke 3: Nét kéo xuống
      [
        { x: 35, y: 50, t: 0 },
        { x: 35, y: 62, t: 50 },
        { x: 35, y: 75, t: 100 },
        { x: 36, y: 85, t: 150 },
      ],
    ],
  },
  {
    character: 'ន',
    romanized: 'no',
    type: 'consonant',
    difficulty: 'easy',
    hint: 'Vẽ nét cong mềm mại giống chữ U ngược',
    standardStrokes: [
      // Stroke 1: Nét U ngược
      [
        { x: 20, y: 70, t: 0 },
        { x: 20, y: 55, t: 40 },
        { x: 22, y: 40, t: 80 },
        { x: 28, y: 28, t: 120 },
        { x: 38, y: 22, t: 160 },
        { x: 48, y: 28, t: 200 },
        { x: 52, y: 40, t: 240 },
        { x: 52, y: 55, t: 280 },
        { x: 52, y: 70, t: 320 },
      ],
    ],
  },
  {
    character: 'ប',
    romanized: 'bo',
    type: 'consonant',
    difficulty: 'easy',
    hint: 'Bắt đầu từ trên, vẽ vòng tròn rồi kéo thẳng xuống',
    standardStrokes: [
      // Stroke 1: Vòng tròn
      [
        { x: 35, y: 20, t: 0 },
        { x: 28, y: 18, t: 35 },
        { x: 20, y: 22, t: 70 },
        { x: 16, y: 32, t: 105 },
        { x: 18, y: 42, t: 140 },
        { x: 25, y: 48, t: 175 },
        { x: 35, y: 48, t: 210 },
        { x: 40, y: 42, t: 245 },
        { x: 40, y: 32, t: 280 },
        { x: 35, y: 22, t: 315 },
      ],
      // Stroke 2: Nét kéo thẳng xuống
      [
        { x: 35, y: 48, t: 0 },
        { x: 35, y: 58, t: 40 },
        { x: 35, y: 68, t: 80 },
        { x: 35, y: 78, t: 120 },
        { x: 35, y: 85, t: 160 },
      ],
    ],
  },
  {
    character: 'ម',
    romanized: 'mo',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Vẽ hai vòng cong nối tiếp nhau',
    standardStrokes: [
      // Stroke 1: Vòng cong trái
      [
        { x: 18, y: 25, t: 0 },
        { x: 15, y: 35, t: 40 },
        { x: 18, y: 48, t: 80 },
        { x: 25, y: 52, t: 120 },
        { x: 32, y: 48, t: 160 },
        { x: 35, y: 38, t: 200 },
      ],
      // Stroke 2: Vòng cong phải
      [
        { x: 35, y: 38, t: 0 },
        { x: 38, y: 48, t: 40 },
        { x: 45, y: 55, t: 80 },
        { x: 55, y: 52, t: 120 },
        { x: 58, y: 42, t: 160 },
        { x: 55, y: 30, t: 200 },
      ],
      // Stroke 3: Nét kéo xuống
      [
        { x: 35, y: 52, t: 0 },
        { x: 35, y: 65, t: 50 },
        { x: 35, y: 78, t: 100 },
        { x: 36, y: 88, t: 150 },
      ],
    ],
  },
  {
    character: 'ឃ',
    romanized: 'kho',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Bắt đầu nét sóng cap trên, vẽ vòng trái rồi móc lên vẽ vòm phải',
    standardStrokes: [
      // Stroke 1: Nét wavy cap
      [
        { x: 30, y: 30, t: 0 },
        { x: 40, y: 25, t: 30 },
        { x: 50, y: 28, t: 60 },
        { x: 60, y: 25, t: 90 },
        { x: 70, y: 30, t: 120 },
      ],
      // Stroke 2: Nét trái & thắt nút
      [
        { x: 35, y: 30, t: 0 },
        { x: 35, y: 50, t: 30 },
        { x: 30, y: 65, t: 60 },
        { x: 40, y: 75, t: 90 },
        { x: 45, y: 60, t: 120 },
      ],
      // Stroke 3: Nét thân phải
      [
        { x: 45, y: 60, t: 0 },
        { x: 50, y: 45, t: 40 },
        { x: 65, y: 45, t: 80 },
        { x: 65, y: 65, t: 120 },
        { x: 65, y: 80, t: 160 },
      ],
    ],
  },
  {
    character: 'ឆ',
    romanized: 'cho',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Vẽ nét trên, thân đứng trái, và một vòng tròn thắt dưới bụng kéo lên',
    standardStrokes: [
      // Stroke 1: Nét cap trên
      [
        { x: 30, y: 30, t: 0 },
        { x: 50, y: 26, t: 50 },
        { x: 70, y: 30, t: 100 },
      ],
      // Stroke 2: Nét đứng trái
      [
        { x: 35, y: 30, t: 0 },
        { x: 35, y: 55, t: 40 },
        { x: 35, y: 80, t: 80 },
        { x: 55, y: 80, t: 120 },
      ],
      // Stroke 3: Nét thắt tròn và móc lên
      [
        { x: 55, y: 80, t: 0 },
        { x: 65, y: 65, t: 30 },
        { x: 50, y: 50, t: 60 },
        { x: 38, y: 65, t: 90 },
        { x: 50, y: 80, t: 120 },
        { x: 65, y: 80, t: 150 },
        { x: 65, y: 55, t: 180 },
      ],
    ],
  },
  {
    character: 'ជ',
    romanized: 'co',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Vẽ nét sóng cap trên, sau đó vẽ vòm thân trái và arch lượn sóng thân phải',
    standardStrokes: [
      // Stroke 1: Nét cap trên
      [
        { x: 30, y: 30, t: 0 },
        { x: 50, y: 25, t: 50 },
        { x: 70, y: 30, t: 100 },
      ],
      // Stroke 2: Nét thân chính
      [
        { x: 35, y: 30, t: 0 },
        { x: 35, y: 55, t: 30 },
        { x: 35, y: 80, t: 60 },
        { x: 55, y: 80, t: 90 },
        { x: 55, y: 50, t: 120 },
        { x: 70, y: 50, t: 150 },
        { x: 70, y: 80, t: 180 },
      ],
    ],
  },
  {
    character: 'ឈ',
    romanized: 'cho',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Mũi sóng trên, thắt nút trái, và arch lượn nét phải kéo thẳng đứng',
    standardStrokes: [
      // Stroke 1: Nét cap trên
      [
        { x: 30, y: 30, t: 0 },
        { x: 50, y: 25, t: 50 },
        { x: 70, y: 30, t: 100 },
      ],
      // Stroke 2: Nét trái & thắt nút giữa
      [
        { x: 35, y: 30, t: 0 },
        { x: 35, y: 55, t: 30 },
        { x: 35, y: 80, t: 60 },
        { x: 50, y: 80, t: 90 },
        { x: 50, y: 60, t: 120 },
        { x: 35, y: 60, t: 150 },
      ],
      // Stroke 3: Nét thân phải
      [
        { x: 50, y: 60, t: 0 },
        { x: 55, y: 45, t: 40 },
        { x: 70, y: 45, t: 80 },
        { x: 70, y: 65, t: 120 },
        { x: 70, y: 80, t: 160 },
      ],
    ],
  },
  {
    character: 'ញ',
    romanized: 'nyo',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Hai nét vòm song song đứng ở thân trên, nét móc nhỏ uốn lượn dưới chân',
    standardStrokes: [
      // Stroke 1: Thân chính
      [
        { x: 30, y: 30, t: 0 },
        { x: 30, y: 50, t: 30 },
        { x: 30, y: 70, t: 60 },
        { x: 50, y: 70, t: 90 },
        { x: 50, y: 45, t: 120 },
        { x: 65, y: 45, t: 150 },
        { x: 65, y: 70, t: 180 },
      ],
      // Stroke 2: Chân phụ dưới
      [
        { x: 30, y: 85, t: 0 },
        { x: 48, y: 92, t: 50 },
        { x: 65, y: 85, t: 100 },
      ],
    ],
  },
  {
    character: 'ឋ',
    romanized: 'tho',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Nét cap trên lượn ngang rồi bo tròn hộp chữ nhật khép kín phía dưới',
    standardStrokes: [
      // Stroke 1: Phần cap và thân trên khép kín
      [
        { x: 30, y: 35, t: 0 },
        { x: 50, y: 30, t: 30 },
        { x: 70, y: 35, t: 60 },
        { x: 70, y: 55, t: 90 },
        { x: 30, y: 55, t: 120 },
        { x: 30, y: 35, t: 150 },
      ],
      // Stroke 2: Nét lượn dưới bụng
      [
        { x: 30, y: 55, t: 0 },
        { x: 30, y: 80, t: 40 },
        { x: 70, y: 80, t: 80 },
        { x: 70, y: 65, t: 120 },
      ],
    ],
  },
  {
    character: 'ឌ',
    romanized: 'do',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Nét sóng cap trên rồi kéo thân đứng xuống dưới lượn một vòm tròn thắt',
    standardStrokes: [
      // Stroke 1: Nét cap trên
      [
        { x: 30, y: 30, t: 0 },
        { x: 50, y: 25, t: 50 },
        { x: 70, y: 30, t: 100 },
      ],
      // Stroke 2: Thân đứng lượn thắt nút
      [
        { x: 35, y: 30, t: 0 },
        { x: 35, y: 55, t: 30 },
        { x: 35, y: 80, t: 60 },
        { x: 65, y: 80, t: 90 },
        { x: 65, y: 55, t: 120 },
        { x: 50, y: 55, t: 150 },
      ],
    ],
  },
  {
    character: 'ឍ',
    romanized: 'tho',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Vẽ đầu chữ, kéo thân dọc xuống, móc lên thắt nút bên phải tròn trịa',
    standardStrokes: [
      // Stroke 1: Nét cap trên
      [
        { x: 30, y: 30, t: 0 },
        { x: 50, y: 25, t: 50 },
        { x: 70, y: 30, t: 100 },
      ],
      // Stroke 2: Thân dọc trái
      [
        { x: 35, y: 30, t: 0 },
        { x: 35, y: 55, t: 40 },
        { x: 35, y: 80, t: 80 },
        { x: 55, y: 80, t: 120 },
        { x: 55, y: 60, t: 160 },
      ],
      // Stroke 3: Nét tròn phải thắt
      [
        { x: 55, y: 60, t: 0 },
        { x: 70, y: 50, t: 40 },
        { x: 70, y: 75, t: 80 },
        { x: 55, y: 75, t: 120 },
      ],
    ],
  },
  {
    character: 'ណ',
    romanized: 'no',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Móc tròn trái lượn lên ngang rồi tạo vòm đứng kéo thẳng dọc xuống phải',
    standardStrokes: [
      // Stroke 1: Nét móc trái thắt nút
      [
        { x: 30, y: 40, t: 0 },
        { x: 30, y: 70, t: 30 },
        { x: 45, y: 70, t: 60 },
        { x: 45, y: 55, t: 90 },
      ],
      // Stroke 2: Nét ngang lượn giữa
      [
        { x: 45, y: 55, t: 0 },
        { x: 58, y: 55, t: 40 },
        { x: 70, y: 55, t: 80 },
      ],
      // Stroke 3: Thân thẳng đứng dọc phải
      [
        { x: 58, y: 55, t: 0 },
        { x: 58, y: 80, t: 40 },
        { x: 70, y: 80, t: 80 },
        { x: 70, y: 40, t: 120 },
      ],
    ],
  },
  {
    character: 'ថ',
    romanized: 'tho',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Vẽ vòm chữ bên trái lượn xuống đáy rồi kéo thẳng dọc đứng phải',
    standardStrokes: [
      // Stroke 1: Vòm trái
      [
        { x: 30, y: 40, t: 0 },
        { x: 30, y: 80, t: 45 },
        { x: 50, y: 80, t: 90 },
        { x: 50, y: 40, t: 135 },
      ],
      // Stroke 2: Thân dọc phải
      [
        { x: 50, y: 40, t: 0 },
        { x: 70, y: 40, t: 40 },
        { x: 70, y: 80, t: 80 },
      ],
    ],
  },
  {
    character: 'ទ',
    romanized: 'to',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Kéo thân dọc trái, thắt nút tròn rồi uốn arch phải hướng đứng xuống',
    standardStrokes: [
      // Stroke 1: Dọc trái
      [
        { x: 30, y: 30, t: 0 },
        { x: 30, y: 55, t: 30 },
        { x: 30, y: 80, t: 60 },
        { x: 45, y: 80, t: 90 },
      ],
      // Stroke 2: Nét thắt tròn
      [
        { x: 45, y: 80, t: 0 },
        { x: 45, y: 55, t: 30 },
        { x: 35, y: 55, t: 60 },
        { x: 45, y: 55, t: 90 },
      ],
      // Stroke 3: Nét vòm phải
      [
        { x: 45, y: 55, t: 0 },
        { x: 50, y: 45, t: 30 },
        { x: 70, y: 45, t: 60 },
        { x: 70, y: 65, t: 90 },
        { x: 70, y: 80, t: 120 },
      ],
    ],
  },
  {
    character: 'ធ',
    romanized: 'tho',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Kéo dọc trái uốn chân rồi bo vòng tròn bụng thắt thòng bên phải',
    standardStrokes: [
      // Stroke 1: Thân đứng trái & đáy
      [
        { x: 30, y: 35, t: 0 },
        { x: 30, y: 80, t: 45 },
        { x: 50, y: 80, t: 90 },
        { x: 50, y: 40, t: 135 },
      ],
      // Stroke 2: Bụng tròn thắt bên phải
      [
        { x: 50, y: 40, t: 0 },
        { x: 70, y: 35, t: 30 },
        { x: 70, y: 65, t: 65 },
        { x: 50, y: 65, t: 100 },
      ],
    ],
  },
  {
    character: 'ផ',
    romanized: 'pho',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Kéo vòm đứng trái uốn chân lên, rồi phẩy chéo nét tóc bay phía trên',
    standardStrokes: [
      // Stroke 1: Vòm đứng và chân
      [
        { x: 30, y: 40, t: 0 },
        { x: 30, y: 80, t: 45 },
        { x: 50, y: 80, t: 90 },
        { x: 50, y: 40, t: 135 },
      ],
      // Stroke 2: Nét tóc chéo
      [
        { x: 50, y: 40, t: 0 },
        { x: 60, y: 28, t: 30 },
        { x: 70, y: 20, t: 60 },
      ],
    ],
  },
  {
    character: 'ព',
    romanized: 'pho',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Vẽ vòm sóng nhỏ bên trái rồi kéo cap ngang trên và đứng thẳng dọc phải',
    standardStrokes: [
      // Stroke 1: Nét lượn sóng trái
      [
        { x: 30, y: 40, t: 0 },
        { x: 30, y: 70, t: 30 },
        { x: 45, y: 70, t: 60 },
        { x: 45, y: 55, t: 90 },
      ],
      // Stroke 2: Nét cap trên ngang
      [
        { x: 45, y: 55, t: 0 },
        { x: 58, y: 55, t: 40 },
        { x: 70, y: 55, t: 80 },
      ],
      // Stroke 3: Thân đứng dọc phải
      [
        { x: 70, y: 55, t: 0 },
        { x: 70, y: 80, t: 50 },
      ],
    ],
  },
  {
    character: 'ភ',
    romanized: 'pho',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Vẽ sóng cap trên, sau đó lượn sóng trái thắt nút dọc, phẩy nét đuôi phải',
    standardStrokes: [
      // Stroke 1: Nét cap trên
      [
        { x: 30, y: 30, t: 0 },
        { x: 50, y: 25, t: 50 },
        { x: 70, y: 30, t: 100 },
      ],
      // Stroke 2: Nét lượn đứng trái thắt
      [
        { x: 35, y: 30, t: 0 },
        { x: 35, y: 55, t: 30 },
        { x: 35, y: 80, t: 60 },
        { x: 50, y: 80, t: 90 },
        { x: 50, y: 60, t: 120 },
      ],
      // Stroke 3: Đuôi chéo phải
      [
        { x: 50, y: 60, t: 0 },
        { x: 60, y: 50, t: 30 },
        { x: 70, y: 40, t: 60 },
      ],
    ],
  },
  {
    character: 'យ',
    romanized: 'yo',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Vẽ vòm chữ bên trái lượn sâu rồi kéo ngang qua để đứng thẳng dọc phải',
    standardStrokes: [
      // Stroke 1: Vòm sâu trái
      [
        { x: 30, y: 40, t: 0 },
        { x: 30, y: 80, t: 45 },
        { x: 50, y: 80, t: 90 },
        { x: 50, y: 40, t: 135 },
      ],
      // Stroke 2: Nét đứng dọc phải
      [
        { x: 50, y: 40, t: 0 },
        { x: 70, y: 40, t: 40 },
        { x: 70, y: 80, t: 80 },
      ],
    ],
  },
  {
    character: 'រ',
    romanized: 'ro',
    type: 'consonant',
    difficulty: 'easy',
    hint: 'Kéo trục đứng dọc thẳng rồi vẽ mũ cờ thắt vòng lên phía trên',
    standardStrokes: [
      // Stroke 1: Nét đứng dọc
      [
        { x: 40, y: 30, t: 0 },
        { x: 40, y: 55, t: 40 },
        { x: 40, y: 80, t: 80 },
      ],
      // Stroke 2: Nét cờ thắt trên đầu
      [
        { x: 40, y: 30, t: 0 },
        { x: 55, y: 25, t: 30 },
        { x: 65, y: 38, t: 60 },
        { x: 50, y: 45, t: 90 },
        { x: 40, y: 45, t: 120 },
      ],
    ],
  },
  {
    character: 'ល',
    romanized: 'lo',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Vẽ vòm đứng trái lượn uốn thắt nút tròn ở đáy rồi arch đứng thẳng đứng phải',
    standardStrokes: [
      // Stroke 1: Vòm uốn đứng trái
      [
        { x: 30, y: 45, t: 0 },
        { x: 30, y: 80, t: 45 },
        { x: 50, y: 80, t: 90 },
      ],
      // Stroke 2: Nét thắt tròn
      [
        { x: 50, y: 80, t: 0 },
        { x: 50, y: 55, t: 30 },
        { x: 38, y: 55, t: 60 },
        { x: 50, y: 55, t: 90 },
      ],
      // Stroke 3: Nét vòm dọc đứng phải
      [
        { x: 50, y: 55, t: 0 },
        { x: 55, y: 45, t: 30 },
        { x: 70, y: 45, t: 60 },
        { x: 70, y: 65, t: 90 },
        { x: 70, y: 80, t: 120 },
      ],
    ],
  },
  {
    character: 'វ',
    romanized: 'vo',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Vẽ bụng vòm đứng trái rồi thắt nút quấn vòng cung chéo lên đầu chữ',
    standardStrokes: [
      // Stroke 1: Thân đứng và đáy trái
      [
        { x: 30, y: 40, t: 0 },
        { x: 30, y: 80, t: 45 },
        { x: 55, y: 80, t: 90 },
      ],
      // Stroke 2: Nét vòng tròn thắt quấn đầu chéo
      [
        { x: 55, y: 80, t: 0 },
        { x: 55, y: 55, t: 30 },
        { x: 40, y: 50, t: 60 },
        { x: 40, y: 30, t: 90 },
      ],
    ],
  },
  {
    character: 'ស',
    romanized: 'so',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Hai nét vòm tròn trái phải liên kết ở giữa, phẩy nét tóc nhọn trên đỉnh đầu',
    standardStrokes: [
      // Stroke 1: Vòm trái
      [
        { x: 30, y: 40, t: 0 },
        { x: 30, y: 80, t: 45 },
        { x: 50, y: 80, t: 90 },
        { x: 50, y: 50, t: 135 },
      ],
      // Stroke 2: Vòm phải
      [
        { x: 50, y: 50, t: 0 },
        { x: 70, y: 50, t: 40 },
        { x: 70, y: 80, t: 80 },
      ],
      // Stroke 3: Nét tóc đỉnh đầu
      [
        { x: 50, y: 50, t: 0 },
        { x: 58, y: 35, t: 30 },
        { x: 65, y: 20, t: 60 },
      ],
    ],
  },
  {
    character: 'ហ',
    romanized: 'ho',
    type: 'consonant',
    difficulty: 'medium',
    hint: 'Vẽ vòm uốn trái thắt nút tròn rồi hất vòm đuôi cao nhọn bên phải',
    standardStrokes: [
      // Stroke 1: Thân đứng và đáy trái
      [
        { x: 30, y: 45, t: 0 },
        { x: 30, y: 80, t: 45 },
        { x: 50, y: 80, t: 90 },
      ],
      // Stroke 2: Nét thắt tròn
      [
        { x: 50, y: 80, t: 0 },
        { x: 50, y: 55, t: 30 },
        { x: 38, y: 55, t: 60 },
        { x: 50, y: 55, t: 90 },
      ],
      // Stroke 3: Nét vòm đuôi nhọn
      [
        { x: 50, y: 55, t: 0 },
        { x: 60, y: 42, t: 30 },
        { x: 70, y: 30, t: 60 },
      ],
    ],
  },
  {
    character: 'ឡ',
    romanized: 'la',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Vẽ hai vòm đứng giống chữ ជ, bổ sung vòng tròn thắt chân đuôi và nét tóc đầu',
    standardStrokes: [
      // Stroke 1: Thân chính ជ
      [
        { x: 30, y: 45, t: 0 },
        { x: 30, y: 80, t: 30 },
        { x: 48, y: 80, t: 60 },
        { x: 48, y: 50, t: 90 },
        { x: 65, y: 50, t: 120 },
        { x: 65, y: 80, t: 150 },
      ],
      // Stroke 2: Nét tròn thắt đuôi
      [
        { x: 65, y: 80, t: 0 },
        { x: 78, y: 72, t: 30 },
        { x: 78, y: 55, t: 60 },
        { x: 65, y: 65, t: 90 },
      ],
      // Stroke 3: Nét tóc chéo
      [
        { x: 65, y: 50, t: 0 },
        { x: 72, y: 35, t: 30 },
        { x: 80, y: 20, t: 60 },
      ],
    ],
  },
  {
    character: 'អ',
    romanized: 'qa',
    type: 'consonant',
    difficulty: 'hard',
    hint: 'Vẽ nét sóng cap ngang, sau đó vẽ đứng trái thắt vòng rồi arch vòm đứng dọc phải',
    standardStrokes: [
      // Stroke 1: Nét cap trên
      [
        { x: 30, y: 30, t: 0 },
        { x: 50, y: 25, t: 50 },
        { x: 70, y: 30, t: 100 },
      ],
      // Stroke 2: Nét đứng trái thắt đáy
      [
        { x: 35, y: 30, t: 0 },
        { x: 35, y: 55, t: 30 },
        { x: 35, y: 80, t: 60 },
        { x: 50, y: 80, t: 90 },
      ],
      // Stroke 3: Vòm đứng dọc phải
      [
        { x: 50, y: 80, t: 0 },
        { x: 55, y: 50, t: 30 },
        { x: 70, y: 50, t: 60 },
        { x: 70, y: 65, t: 90 },
        { x: 70, y: 80, t: 120 },
      ],
    ],
  },

  // ══════════════════════════════════════
  // VOWELS
  // ══════════════════════════════════════
  {
    character: 'ា',
    romanized: 'aa',
    type: 'vowel',
    difficulty: 'easy',
    hint: 'Nét móc từ trên xuống dưới bên phải phụ âm',
    standardStrokes: [
      // Stroke 1: Nét móc cong thẳng đứng bên phải
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
      ],
    ],
  },
  {
    character: 'ិ',
    romanized: 'i',
    type: 'vowel',
    difficulty: 'easy',
    hint: 'Dấu nhỏ đặt phía trên phụ âm',
    standardStrokes: [
      // Stroke 1: Nét vòm cong hình bán nguyệt (kéo từ phải sang trái, vòng lên rồi cong xuống khép kín)
      [
        { x: 60, y: 22, t: 0 },
        { x: 53, y: 22, t: 20 },
        { x: 46, y: 22, t: 40 },
        { x: 40, y: 22, t: 60 },
        { x: 41, y: 16, t: 80 },
        { x: 45, y: 12, t: 100 },
        { x: 50, y: 10, t: 120 },
        { x: 55, y: 12, t: 140 },
        { x: 59, y: 16, t: 160 },
        { x: 60, y: 22, t: 180 },
      ],
    ],
  },
  {
    character: 'ី',
    romanized: 'ii',
    type: 'vowel',
    difficulty: 'easy',
    hint: 'Hai dấu nhỏ đặt phía trên phụ âm',
    standardStrokes: [
      // Stroke 1: Nét vòm cong (giống ិ)
      [
        { x: 60, y: 22, t: 0 },
        { x: 53, y: 22, t: 20 },
        { x: 46, y: 22, t: 40 },
        { x: 40, y: 22, t: 60 },
        { x: 41, y: 16, t: 80 },
        { x: 45, y: 12, t: 100 },
        { x: 50, y: 10, t: 120 },
        { x: 55, y: 12, t: 140 },
        { x: 59, y: 16, t: 160 },
        { x: 60, y: 22, t: 180 },
      ],
      // Stroke 2: Nét gạch đứng nhỏ bên trong (kéo từ trên xuống dưới)
      [
        { x: 50, y: 13, t: 0 },
        { x: 50, y: 17, t: 45 },
        { x: 50, y: 21, t: 90 },
      ],
    ],
  },
  {
    character: 'ុ',
    romanized: 'u',
    type: 'vowel',
    difficulty: 'easy',
    hint: 'Dấu nhỏ đặt phía dưới phụ âm',
    standardStrokes: [
      // Stroke 1: Nét cong nhỏ phía dưới
      [
        { x: 40, y: 82, t: 0 },
        { x: 45, y: 88, t: 40 },
        { x: 50, y: 90, t: 80 },
        { x: 55, y: 88, t: 120 },
        { x: 58, y: 82, t: 160 },
      ],
    ],
  },
  {
    character: 'ូ',
    romanized: 'uu',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Dấu dưới kết hợp với nét bên phải',
    standardStrokes: [
      // Stroke 1: Nét cong dưới
      [
        { x: 38, y: 82, t: 0 },
        { x: 42, y: 88, t: 40 },
        { x: 48, y: 90, t: 80 },
        { x: 54, y: 88, t: 120 },
        { x: 56, y: 82, t: 160 },
      ],
      // Stroke 2: Nét thẳng bên phải
      [
        { x: 65, y: 20, t: 0 },
        { x: 65, y: 35, t: 40 },
        { x: 65, y: 50, t: 80 },
        { x: 65, y: 65, t: 120 },
        { x: 65, y: 80, t: 160 },
      ],
    ],
  },
  {
    character: 'ឹ',
    romanized: 'ə',
    type: 'vowel',
    difficulty: 'easy',
    hint: 'Dấu nhỏ phía trên phụ âm giống ិ nhưng có thêm nét ngang',
    standardStrokes: [
      // Stroke 1: Nét vòm cong (giống ិ)
      [
        { x: 60, y: 22, t: 0 },
        { x: 53, y: 22, t: 20 },
        { x: 46, y: 22, t: 40 },
        { x: 40, y: 22, t: 60 },
        { x: 41, y: 16, t: 80 },
        { x: 45, y: 12, t: 100 },
        { x: 50, y: 10, t: 120 },
        { x: 55, y: 12, t: 140 },
        { x: 59, y: 16, t: 160 },
        { x: 60, y: 22, t: 180 },
      ],
      // Stroke 2: Vòng tròn nhỏ phía trên bên phải
      [
        { x: 58, y: 10, t: 0 },
        { x: 55, y: 6, t: 30 },
        { x: 52, y: 10, t: 60 },
        { x: 55, y: 14, t: 90 },
        { x: 58, y: 10, t: 120 },
      ],
    ],
  },
  {
    character: 'ឺ',
    romanized: 'əə',
    type: 'vowel',
    difficulty: 'easy',
    hint: 'Hai dấu nhỏ phía trên phụ âm có thêm nét ngang',
    standardStrokes: [
      // Stroke 1: Nét vòm cong (giống ិ)
      [
        { x: 60, y: 22, t: 0 },
        { x: 53, y: 22, t: 20 },
        { x: 46, y: 22, t: 40 },
        { x: 40, y: 22, t: 60 },
        { x: 41, y: 16, t: 80 },
        { x: 45, y: 12, t: 100 },
        { x: 50, y: 10, t: 120 },
        { x: 55, y: 12, t: 140 },
        { x: 59, y: 16, t: 160 },
        { x: 60, y: 22, t: 180 },
      ],
      // Stroke 2: Nét gạch đứng thứ nhất bên trong
      [
        { x: 46, y: 13, t: 0 },
        { x: 46, y: 21, t: 60 },
      ],
      // Stroke 3: Nét gạch đứng thứ hai bên trong
      [
        { x: 54, y: 13, t: 0 },
        { x: 54, y: 21, t: 60 },
      ],
    ],
  },
  {
    character: 'ួ',
    romanized: 'uə',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Nét cong dưới kết hợp nét phía trên bên trái',
    standardStrokes: [
      // Stroke 1: Nét cong phía dưới
      [
        { x: 38, y: 82, t: 0 },
        { x: 42, y: 88, t: 40 },
        { x: 48, y: 90, t: 80 },
        { x: 54, y: 88, t: 120 },
        { x: 56, y: 82, t: 160 },
      ],
      // Stroke 2: Nét vòng phía trên bên trái
      [
        { x: 25, y: 30, t: 0 },
        { x: 22, y: 24, t: 40 },
        { x: 25, y: 18, t: 80 },
        { x: 30, y: 16, t: 120 },
        { x: 34, y: 20, t: 160 },
        { x: 32, y: 28, t: 200 },
        { x: 28, y: 32, t: 240 },
      ],
    ],
  },
  {
    character: 'ើ',
    romanized: 'əə',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Nét bên trái giống e rồi thêm nét thẳng đứng bên phải',
    standardStrokes: [
      // Stroke 1: Nét cong bên trái (giống េ)
      [
        { x: 18, y: 45, t: 0 },
        { x: 15, y: 38, t: 40 },
        { x: 18, y: 30, t: 80 },
        { x: 24, y: 28, t: 120 },
        { x: 28, y: 35, t: 160 },
        { x: 25, y: 42, t: 200 },
        { x: 20, y: 45, t: 240 },
      ],
      // Stroke 2: Nét thẳng đứng bên phải
      [
        { x: 65, y: 20, t: 0 },
        { x: 65, y: 35, t: 40 },
        { x: 65, y: 50, t: 80 },
        { x: 65, y: 65, t: 120 },
        { x: 65, y: 80, t: 160 },
      ],
    ],
  },
  {
    character: 'ឿ',
    romanized: 'ɨə',
    type: 'vowel',
    difficulty: 'hard',
    hint: 'Nét cong bên trái kết hợp nét cong phía trên phải',
    standardStrokes: [
      // Stroke 1: Nét cong bên trái
      [
        { x: 18, y: 45, t: 0 },
        { x: 15, y: 38, t: 40 },
        { x: 18, y: 30, t: 80 },
        { x: 24, y: 28, t: 120 },
        { x: 28, y: 35, t: 160 },
        { x: 25, y: 42, t: 200 },
        { x: 20, y: 45, t: 240 },
      ],
      // Stroke 2: Nét vòng nhỏ phía trên bên phải
      [
        { x: 55, y: 18, t: 0 },
        { x: 60, y: 14, t: 40 },
        { x: 65, y: 16, t: 80 },
        { x: 66, y: 22, t: 120 },
        { x: 62, y: 25, t: 160 },
        { x: 58, y: 22, t: 200 },
      ],
    ],
  },
  {
    character: 'ៀ',
    romanized: 'iə',
    type: 'vowel',
    difficulty: 'hard',
    hint: 'Nét cong bên trái kết hợp dấu nhỏ phía trên',
    standardStrokes: [
      // Stroke 1: Nét cong bên trái (giống េ)
      [
        { x: 18, y: 45, t: 0 },
        { x: 15, y: 38, t: 40 },
        { x: 18, y: 30, t: 80 },
        { x: 24, y: 28, t: 120 },
        { x: 28, y: 35, t: 160 },
        { x: 25, y: 42, t: 200 },
        { x: 20, y: 45, t: 240 },
      ],
      // Stroke 2: Dấu nhỏ phía trên (giống ិ)
      [
        { x: 60, y: 22, t: 0 },
        { x: 53, y: 22, t: 20 },
        { x: 46, y: 22, t: 40 },
        { x: 40, y: 22, t: 60 },
        { x: 41, y: 16, t: 80 },
        { x: 45, y: 12, t: 100 },
        { x: 50, y: 10, t: 120 },
        { x: 55, y: 12, t: 140 },
        { x: 59, y: 16, t: 160 },
        { x: 60, y: 22, t: 180 },
      ],
    ],
  },
  {
    character: 'េ',
    romanized: 'ee',
    type: 'vowel',
    difficulty: 'easy',
    hint: 'Nét cong vòng nhỏ đặt bên trái phụ âm',
    standardStrokes: [
      // Stroke 1: Nét cong vòng bên trái
      [
        { x: 22, y: 45, t: 0 },
        { x: 18, y: 38, t: 40 },
        { x: 18, y: 30, t: 80 },
        { x: 22, y: 24, t: 120 },
        { x: 28, y: 24, t: 160 },
        { x: 32, y: 30, t: 200 },
        { x: 30, y: 38, t: 240 },
        { x: 25, y: 44, t: 280 },
      ],
    ],
  },
  {
    character: 'ែ',
    romanized: 'ae',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Hai nét cong vòng đặt bên trái phụ âm',
    standardStrokes: [
      // Stroke 1: Nét cong vòng ngoài (bên trái hơn)
      [
        { x: 14, y: 45, t: 0 },
        { x: 10, y: 38, t: 40 },
        { x: 10, y: 30, t: 80 },
        { x: 14, y: 24, t: 120 },
        { x: 20, y: 24, t: 160 },
        { x: 24, y: 30, t: 200 },
        { x: 22, y: 38, t: 240 },
        { x: 17, y: 44, t: 280 },
      ],
      // Stroke 2: Nét cong vòng trong
      [
        { x: 26, y: 45, t: 0 },
        { x: 22, y: 38, t: 40 },
        { x: 22, y: 30, t: 80 },
        { x: 26, y: 24, t: 120 },
        { x: 32, y: 24, t: 160 },
        { x: 36, y: 30, t: 200 },
        { x: 34, y: 38, t: 240 },
        { x: 29, y: 44, t: 280 },
      ],
    ],
  },
  {
    character: 'ៃ',
    romanized: 'aj',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Nét cong bên trái có đuôi chéo lên phải',
    standardStrokes: [
      // Stroke 1: Nét cong bên trái rồi kéo chéo lên
      [
        { x: 22, y: 48, t: 0 },
        { x: 18, y: 40, t: 40 },
        { x: 18, y: 32, t: 80 },
        { x: 22, y: 26, t: 120 },
        { x: 28, y: 26, t: 160 },
        { x: 32, y: 32, t: 200 },
        { x: 30, y: 40, t: 240 },
        { x: 25, y: 46, t: 280 },
        { x: 30, y: 38, t: 320 },
        { x: 38, y: 28, t: 360 },
        { x: 45, y: 18, t: 400 },
      ],
    ],
  },
  {
    character: 'ោ',
    romanized: 'ao',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Nét cong bên trái kết hợp nét thẳng đứng bên phải có cong trên',
    standardStrokes: [
      // Stroke 1: Nét cong bên trái
      [
        { x: 22, y: 45, t: 0 },
        { x: 18, y: 38, t: 40 },
        { x: 18, y: 30, t: 80 },
        { x: 22, y: 24, t: 120 },
        { x: 28, y: 24, t: 160 },
        { x: 32, y: 30, t: 200 },
        { x: 30, y: 38, t: 240 },
        { x: 25, y: 44, t: 280 },
      ],
      // Stroke 2: Nét thẳng đứng bên phải có cong trên
      [
        { x: 62, y: 18, t: 0 },
        { x: 66, y: 22, t: 40 },
        { x: 65, y: 30, t: 80 },
        { x: 65, y: 45, t: 120 },
        { x: 65, y: 60, t: 160 },
        { x: 65, y: 75, t: 200 },
        { x: 65, y: 85, t: 240 },
      ],
    ],
  },
  {
    character: 'ៅ',
    romanized: 'aw',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Nét cong bên trái kết hợp nét cong bên phải có đuôi',
    standardStrokes: [
      // Stroke 1: Nét cong bên trái
      [
        { x: 22, y: 45, t: 0 },
        { x: 18, y: 38, t: 40 },
        { x: 18, y: 30, t: 80 },
        { x: 22, y: 24, t: 120 },
        { x: 28, y: 24, t: 160 },
        { x: 32, y: 30, t: 200 },
        { x: 30, y: 38, t: 240 },
        { x: 25, y: 44, t: 280 },
      ],
      // Stroke 2: Nét bên phải có cong rồi chéo lên
      [
        { x: 62, y: 18, t: 0 },
        { x: 66, y: 22, t: 40 },
        { x: 65, y: 30, t: 80 },
        { x: 65, y: 45, t: 120 },
        { x: 65, y: 60, t: 160 },
        { x: 68, y: 55, t: 200 },
        { x: 72, y: 48, t: 240 },
        { x: 76, y: 40, t: 280 },
      ],
    ],
  },
  {
    character: 'ំ',
    romanized: 'ɑm',
    type: 'vowel',
    difficulty: 'easy',
    hint: 'Dấu chấm tròn nhỏ đặt phía trên phụ âm',
    standardStrokes: [
      // Stroke 1: Vòng tròn nhỏ phía trên
      [
        { x: 48, y: 10, t: 0 },
        { x: 52, y: 8, t: 30 },
        { x: 55, y: 10, t: 60 },
        { x: 55, y: 14, t: 90 },
        { x: 52, y: 16, t: 120 },
        { x: 48, y: 14, t: 150 },
        { x: 48, y: 10, t: 180 },
      ],
    ],
  },
  {
    character: 'ុំ',
    romanized: 'om',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Nét cong dưới kết hợp dấu chấm tròn phía trên',
    standardStrokes: [
      // Stroke 1: Nét cong phía dưới (giống ុ)
      [
        { x: 40, y: 82, t: 0 },
        { x: 45, y: 88, t: 40 },
        { x: 50, y: 90, t: 80 },
        { x: 55, y: 88, t: 120 },
        { x: 58, y: 82, t: 160 },
      ],
      // Stroke 2: Vòng tròn nhỏ phía trên (giống ំ)
      [
        { x: 48, y: 10, t: 0 },
        { x: 52, y: 8, t: 30 },
        { x: 55, y: 10, t: 60 },
        { x: 55, y: 14, t: 90 },
        { x: 52, y: 16, t: 120 },
        { x: 48, y: 14, t: 150 },
        { x: 48, y: 10, t: 180 },
      ],
    ],
  },
  {
    character: 'ះ',
    romanized: 'ah',
    type: 'vowel',
    difficulty: 'easy',
    hint: 'Hai dấu chấm nhỏ đặt bên phải phụ âm',
    standardStrokes: [
      // Stroke 1: Chấm trên
      [
        { x: 65, y: 35, t: 0 },
        { x: 68, y: 33, t: 30 },
        { x: 70, y: 35, t: 60 },
        { x: 68, y: 37, t: 90 },
        { x: 65, y: 35, t: 120 },
      ],
      // Stroke 2: Chấm dưới
      [
        { x: 65, y: 55, t: 0 },
        { x: 68, y: 53, t: 30 },
        { x: 70, y: 55, t: 60 },
        { x: 68, y: 57, t: 90 },
        { x: 65, y: 55, t: 120 },
      ],
    ],
  },
  {
    character: 'ាំ',
    romanized: 'am',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Nét móc bên phải kết hợp dấu chấm tròn phía trên',
    standardStrokes: [
      // Stroke 1: Nét móc cong thẳng đứng bên phải (giống ា)
      [
        { x: 50, y: 35, t: 0 },
        { x: 54, y: 28, t: 20 },
        { x: 60, y: 23, t: 40 },
        { x: 66, y: 20, t: 60 },
        { x: 72, y: 23, t: 80 },
        { x: 75, y: 30, t: 100 },
        { x: 75, y: 45, t: 120 },
        { x: 75, y: 62, t: 140 },
        { x: 75, y: 80, t: 160 },
      ],
      // Stroke 2: Vòng tròn nhỏ phía trên (giống ំ)
      [
        { x: 48, y: 10, t: 0 },
        { x: 52, y: 8, t: 30 },
        { x: 55, y: 10, t: 60 },
        { x: 55, y: 14, t: 90 },
        { x: 52, y: 16, t: 120 },
        { x: 48, y: 14, t: 150 },
        { x: 48, y: 10, t: 180 },
      ],
    ],
  },
  {
    character: 'ិះ',
    romanized: 'eh',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Dấu nhỏ phía trên kết hợp hai chấm bên phải',
    standardStrokes: [
      // Stroke 1: Dấu nhỏ phía trên (giống ិ)
      [
        { x: 60, y: 22, t: 0 },
        { x: 53, y: 22, t: 20 },
        { x: 46, y: 22, t: 40 },
        { x: 40, y: 22, t: 60 },
        { x: 41, y: 16, t: 80 },
        { x: 45, y: 12, t: 100 },
        { x: 50, y: 10, t: 120 },
        { x: 55, y: 12, t: 140 },
        { x: 59, y: 16, t: 160 },
        { x: 60, y: 22, t: 180 },
      ],
      // Stroke 2: Chấm trên bên phải
      [
        { x: 65, y: 35, t: 0 },
        { x: 68, y: 33, t: 30 },
        { x: 70, y: 35, t: 60 },
        { x: 68, y: 37, t: 90 },
        { x: 65, y: 35, t: 120 },
      ],
      // Stroke 3: Chấm dưới bên phải
      [
        { x: 65, y: 55, t: 0 },
        { x: 68, y: 53, t: 30 },
        { x: 70, y: 55, t: 60 },
        { x: 68, y: 57, t: 90 },
        { x: 65, y: 55, t: 120 },
      ],
    ],
  },
  {
    character: 'ុះ',
    romanized: 'oh',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Nét cong dưới kết hợp hai chấm bên phải',
    standardStrokes: [
      // Stroke 1: Nét cong phía dưới (giống ុ)
      [
        { x: 40, y: 82, t: 0 },
        { x: 45, y: 88, t: 40 },
        { x: 50, y: 90, t: 80 },
        { x: 55, y: 88, t: 120 },
        { x: 58, y: 82, t: 160 },
      ],
      // Stroke 2: Chấm trên bên phải
      [
        { x: 65, y: 35, t: 0 },
        { x: 68, y: 33, t: 30 },
        { x: 70, y: 35, t: 60 },
        { x: 68, y: 37, t: 90 },
        { x: 65, y: 35, t: 120 },
      ],
      // Stroke 3: Chấm dưới bên phải
      [
        { x: 65, y: 55, t: 0 },
        { x: 68, y: 53, t: 30 },
        { x: 70, y: 55, t: 60 },
        { x: 68, y: 57, t: 90 },
        { x: 65, y: 55, t: 120 },
      ],
    ],
  },
  {
    character: 'េះ',
    romanized: 'eh',
    type: 'vowel',
    difficulty: 'medium',
    hint: 'Nét cong bên trái kết hợp hai chấm bên phải',
    standardStrokes: [
      // Stroke 1: Nét cong vòng bên trái (giống េ)
      [
        { x: 22, y: 45, t: 0 },
        { x: 18, y: 38, t: 40 },
        { x: 18, y: 30, t: 80 },
        { x: 22, y: 24, t: 120 },
        { x: 28, y: 24, t: 160 },
        { x: 32, y: 30, t: 200 },
        { x: 30, y: 38, t: 240 },
        { x: 25, y: 44, t: 280 },
      ],
      // Stroke 2: Chấm trên bên phải
      [
        { x: 65, y: 35, t: 0 },
        { x: 68, y: 33, t: 30 },
        { x: 70, y: 35, t: 60 },
        { x: 68, y: 37, t: 90 },
        { x: 65, y: 35, t: 120 },
      ],
      // Stroke 3: Chấm dưới bên phải
      [
        { x: 65, y: 55, t: 0 },
        { x: 68, y: 53, t: 30 },
        { x: 70, y: 55, t: 60 },
        { x: 68, y: 57, t: 90 },
        { x: 65, y: 55, t: 120 },
      ],
    ],
  },
  {
    character: 'ោះ',
    romanized: 'oah',
    type: 'vowel',
    difficulty: 'hard',
    hint: 'Nét cong bên trái kết hợp nét đứng bên phải có cong trên và hai chấm',
    standardStrokes: [
      // Stroke 1: Nét cong bên trái (giống េ)
      [
        { x: 22, y: 45, t: 0 },
        { x: 18, y: 38, t: 40 },
        { x: 18, y: 30, t: 80 },
        { x: 22, y: 24, t: 120 },
        { x: 28, y: 24, t: 160 },
        { x: 32, y: 30, t: 200 },
        { x: 30, y: 38, t: 240 },
        { x: 25, y: 44, t: 280 },
      ],
      // Stroke 2: Nét đứng bên phải có cong trên (giống ោ)
      [
        { x: 62, y: 18, t: 0 },
        { x: 66, y: 22, t: 40 },
        { x: 65, y: 30, t: 80 },
        { x: 65, y: 45, t: 120 },
        { x: 65, y: 60, t: 160 },
        { x: 65, y: 75, t: 200 },
      ],
      // Stroke 3: Chấm trên bên phải ngoài
      [
        { x: 75, y: 35, t: 0 },
        { x: 78, y: 33, t: 30 },
        { x: 80, y: 35, t: 60 },
        { x: 78, y: 37, t: 90 },
        { x: 75, y: 35, t: 120 },
      ],
      // Stroke 4: Chấm dưới bên phải ngoài
      [
        { x: 75, y: 55, t: 0 },
        { x: 78, y: 53, t: 30 },
        { x: 80, y: 55, t: 60 },
        { x: 78, y: 57, t: 90 },
        { x: 75, y: 55, t: 120 },
      ],
    ],
  },
];

// ═══════════════════════════════════════════════════════════════════════
// Seed Function
// ═══════════════════════════════════════════════════════════════════════

async function seedStandardCharacters() {
  try {
    console.log('');
    console.log('╔═══════════════════════════════════════════╗');
    console.log('║  📝 Seeding Standard Khmer Characters...  ║');
    console.log('╚═══════════════════════════════════════════╝');
    console.log('');

    await connectDB();

    let created = 0;
    let updated = 0;
    let skipped = 0;

    for (const charData of CHARACTERS) {
      try {
        const existing = await StandardCharacter.findOne({
          character: charData.character,
        });

        if (existing) {
          // Update existing document with new stroke data
          existing.standardStrokes = charData.standardStrokes;
          existing.totalStrokes = charData.standardStrokes.length;
          existing.romanized = charData.romanized;
          existing.type = charData.type;
          existing.difficulty = charData.difficulty;
          existing.hint = charData.hint;
          existing.isActive = true;
          await existing.save();
          updated++;
          console.log(`  🔄 Updated: ${charData.character} (${charData.romanized})`);
        } else {
          const doc = new StandardCharacter({
            ...charData,
            totalStrokes: charData.standardStrokes.length,
          });
          await doc.save();
          created++;
          console.log(`  ✅ Created: ${charData.character} (${charData.romanized})`);
        }
      } catch (charErr) {
        console.error(
          `  ❌ Error processing ${charData.character}: ${charErr.message}`
        );
        skipped++;
      }
    }

    console.log('');
    console.log('╔═══════════════════════════════════════════╗');
    console.log(`║  ✅ Seeding Complete!                      ║`);
    console.log(`║  Created: ${String(created).padEnd(4)} | Updated: ${String(updated).padEnd(4)} | Skip: ${String(skipped).padEnd(4)}║`);
    console.log(`║  Total characters: ${String(CHARACTERS.length).padEnd(22)}║`);
    console.log('╚═══════════════════════════════════════════╝');
    console.log('');

  } catch (err) {
    console.error('❌ Seeder failed:', err.message);
    throw err;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Run if invoked directly
// ═══════════════════════════════════════════════════════════════════════

if (require.main === module) {
  seedStandardCharacters()
    .then(() => {
      console.log('🏁 Seeder finished. Exiting...');
      process.exit(0);
    })
    .catch((err) => {
      console.error('💥 Seeder crashed:', err);
      process.exit(1);
    });
}

module.exports = { seedStandardCharacters, CHARACTERS };
