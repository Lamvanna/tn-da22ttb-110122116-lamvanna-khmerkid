/**
 * ========================================
 * Skill Routes (Listening, Speaking, Writing, Reading)
 * ========================================
 */

const router = require('express').Router();
const listeningController = require('../controllers/listeningController');
const speakingController = require('../controllers/speakingController');
const writingController = require('../controllers/writingController');
const readingController = require('../controllers/readingController');
const { authenticate } = require('../middlewares/auth');
const { validate } = require('../middlewares/validate');
const { uploadAudio } = require('../middlewares/upload');
const {
  listeningResultValidator,
  speakingCheckValidator,
  writingCheckValidator,
  readingResultValidator,
} = require('../validators');

// ========================================
// Listening Routes - /api/listening/*
// ========================================
const listeningRouter = require('express').Router();
listeningRouter.use(authenticate);
listeningRouter.get('/lessons', listeningController.getLessons);
listeningRouter.post('/result', listeningResultValidator, validate, listeningController.saveResult);

// ========================================
// Speaking Routes - /api/speaking/*
// ========================================
const speakingRouter = require('express').Router();
speakingRouter.use(authenticate);
speakingRouter.post('/check', speakingCheckValidator, validate, speakingController.checkPronunciation);
speakingRouter.post('/upload', uploadAudio, speakingController.uploadAudio);

// ========================================
// Writing Routes - /api/writing/*
// ========================================
const writingRouter = require('express').Router();
writingRouter.use(authenticate);
writingRouter.post('/check', writingCheckValidator, validate, writingController.checkWriting);
writingRouter.post('/save', writingController.saveResult);

// ========================================
// Reading Routes - /api/reading/*
// ========================================
const readingRouter = require('express').Router();
readingRouter.use(authenticate);
readingRouter.get('/lessons', readingController.getLessons);
readingRouter.post('/result', readingResultValidator, validate, readingController.saveResult);

module.exports = {
  listeningRouter,
  speakingRouter,
  writingRouter,
  readingRouter,
};
