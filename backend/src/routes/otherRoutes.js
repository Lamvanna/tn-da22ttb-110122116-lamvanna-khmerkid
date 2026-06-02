/**
 * ========================================
 * Game, Mission, Badge, Rank, Upload, Admin Routes
 * ========================================
 */

const { authenticate, optionalAuth } = require('../middlewares/auth');
const { authorize } = require('../middlewares/role');
const { validate } = require('../middlewares/validate');
const { uploadImage, uploadAudio } = require('../middlewares/upload');
const { uploadLimiter } = require('../middlewares/rateLimiter');
const gameController = require('../controllers/gameController');
const adminController = require('../controllers/adminController');
const {
  missionController,
  badgeController,
  rankController,
  uploadController,
} = require('../controllers/missionController');
const {
  gameResultValidator,
  claimMissionValidator,
  idParamValidator,
} = require('../validators');

// ========================================
// Game Routes - /api/games/*
// ========================================
const gameRouter = require('express').Router();
gameRouter.use(authenticate);
gameRouter.post('/result', gameResultValidator, validate, gameController.saveResult);
gameRouter.get('/history', gameController.getHistory);

// ========================================
// Mission Routes - /api/missions/*
// ========================================
const missionRouter = require('express').Router();
missionRouter.use(authenticate);
missionRouter.get('/', missionController.getMissions);
missionRouter.post('/claim', claimMissionValidator, validate, missionController.claimReward);

// ========================================
// Badge Routes - /api/badges, /api/achievements
// ========================================
const badgeRouter = require('express').Router();
badgeRouter.use(authenticate);
badgeRouter.get('/', badgeController.getBadges);

const achievementRouter = require('express').Router();
achievementRouter.use(authenticate);
achievementRouter.get('/', badgeController.getAchievements);

// ========================================
// Rank Routes - /api/rank/*
// ========================================
const rankRouter = require('express').Router();
rankRouter.use(optionalAuth);
rankRouter.get('/top', rankController.getTopRanking);
rankRouter.get('/weekly', rankController.getWeeklyRanking);
rankRouter.get('/monthly', rankController.getMonthlyRanking);

// ========================================
// Upload Routes - /api/upload/*
// ========================================
const uploadRouter = require('express').Router();
uploadRouter.use(authenticate);
uploadRouter.use(uploadLimiter);
// Cho phép học sinh upload ảnh đại diện (avatar) của mình lên Cloudinary
uploadRouter.post('/image', uploadImage, uploadController.uploadImage);
uploadRouter.post('/audio', authorize('admin'), uploadAudio, uploadController.uploadAudio);
uploadRouter.delete('/:publicId', authorize('admin'), uploadController.deleteFile);

// ========================================
// Admin Routes - /api/admin/*
// ========================================
const adminRouter = require('express').Router();
adminRouter.use(authenticate);
adminRouter.use(authorize('admin'));
adminRouter.get('/dashboard', adminController.getDashboard);
adminRouter.get('/statistics', adminController.getStatistics);
adminRouter.get('/users', adminController.getUsers);
adminRouter.delete('/users/:id', idParamValidator, validate, adminController.deleteUser);

module.exports = {
  gameRouter,
  missionRouter,
  badgeRouter,
  achievementRouter,
  rankRouter,
  uploadRouter,
  adminRouter,
};
