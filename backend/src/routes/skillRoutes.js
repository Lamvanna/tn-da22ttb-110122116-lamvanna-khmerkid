/**
 * ========================================
 * Skill Routes (Listening, Speaking, Writing, Reading)
 * ========================================
 */

const router = require('express').Router();
const listeningController = require('../controllers/listeningController');
// const writingController = require('../controllers/writingController');
const readingController = require('../controllers/readingController');
const { authenticate } = require('../middlewares/auth');
const { validate } = require('../middlewares/validate');
const { uploadAudio } = require('../middlewares/upload');
const {
  listeningResultValidator,
  // writingCheckValidator,
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
// Reading Routes - /api/reading/*
// ========================================
const readingRouter = require('express').Router();
readingRouter.use(authenticate);
readingRouter.get('/lessons', readingController.getLessons);
readingRouter.post('/result', readingResultValidator, validate, readingController.saveResult);

module.exports = {
  listeningRouter,
  readingRouter,
};
