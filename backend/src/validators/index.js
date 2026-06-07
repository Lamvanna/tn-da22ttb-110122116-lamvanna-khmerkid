/**
 * ========================================
 * All Validators (combined)
 * ========================================
 */

const { body, param, query } = require('express-validator');
const { LESSON_TYPES, GAME_TYPES, DIFFICULTY } = require('../constants');

// ========================================
// User Validators
// ========================================
const updateProfileValidator = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 }).withMessage('Tên từ 2-50 ký tự'),
  body('avatar')
    .optional()
    .isString(),
];

// ========================================
// Lesson Validators
// ========================================
const createLessonValidator = [
  body('title').trim().notEmpty().withMessage('Tiêu đề bài học là bắt buộc'),
  body('type')
    .notEmpty().withMessage('Loại bài học là bắt buộc')
    .isIn(Object.values(LESSON_TYPES)).withMessage('Loại bài học không hợp lệ'),
  body('khmerText').notEmpty().withMessage('Chữ Khmer là bắt buộc'),
  body('difficulty')
    .optional()
    .isIn(Object.values(DIFFICULTY)).withMessage('Độ khó không hợp lệ'),
];

const updateLessonValidator = [
  body('title').optional().trim().notEmpty().withMessage('Tiêu đề không được trống'),
  body('type')
    .optional()
    .isIn(Object.values(LESSON_TYPES)).withMessage('Loại bài học không hợp lệ'),
  body('difficulty')
    .optional()
    .isIn(Object.values(DIFFICULTY)).withMessage('Độ khó không hợp lệ'),
];

// ========================================
// Listening Validators
// ========================================
const listeningResultValidator = [
  body('correctAnswers').isInt({ min: 0 }).withMessage('Số câu đúng phải >= 0'),
  body('totalQuestions').isInt({ min: 1 }).withMessage('Tổng số câu phải >= 1'),
];



// ========================================
// Writing Validators
// ========================================
const writingCheckValidator = [
  body('score')
    .optional()
    .isInt({ min: 0, max: 100 }).withMessage('Điểm phải từ 0-100'),
];

// ========================================
// Reading Validators
// ========================================
const readingResultValidator = [
  body('wordsRead').isInt({ min: 0 }).withMessage('Số từ đọc phải >= 0'),
  body('totalWords').isInt({ min: 1 }).withMessage('Tổng số từ phải >= 1'),
];

// ========================================
// Game Validators
// ========================================
const gameResultValidator = [
  body('gameType')
    .notEmpty().withMessage('Loại game là bắt buộc')
    .isIn(Object.values(GAME_TYPES)).withMessage('Loại game không hợp lệ'),
  body('score').isInt({ min: 0 }).withMessage('Điểm phải >= 0'),
];

// ========================================
// Mission Validators
// ========================================
const claimMissionValidator = [
  body('missionId').notEmpty().withMessage('Mission ID là bắt buộc'),
];

// ========================================
// ID Param Validator
// ========================================
const idParamValidator = [
  param('id').isMongoId().withMessage('ID không hợp lệ'),
];

module.exports = {
  updateProfileValidator,
  createLessonValidator,
  updateLessonValidator,
  listeningResultValidator,
  writingCheckValidator,
  readingResultValidator,
  gameResultValidator,
  claimMissionValidator,
  idParamValidator,
};
