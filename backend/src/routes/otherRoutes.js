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
const libraryController = require('../controllers/libraryController');
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
gameRouter.get('/questions', gameController.getQuestions);

// ========================================
// Library Routes - /api/library/*
// ========================================
const libraryRouter = require('express').Router();
libraryRouter.use(authenticate);
libraryRouter.get('/', libraryController.getLibraryItems);

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

// Dashboard & Statistics
adminRouter.get('/dashboard', adminController.getDashboard);
adminRouter.get('/statistics', adminController.getStatistics);

// User management
adminRouter.get('/users', adminController.getUsers);
adminRouter.put('/users/:id/role', idParamValidator, validate, adminController.updateUserRole);
adminRouter.delete('/users/:id', idParamValidator, validate, adminController.deleteUser);

// Lesson management
adminRouter.get('/lessons', adminController.getLessons);
adminRouter.post('/lessons', adminController.createLesson);
adminRouter.put('/lessons/:id', idParamValidator, validate, adminController.updateLesson);
adminRouter.delete('/lessons/:id', idParamValidator, validate, adminController.deleteLesson);

// Mission management
adminRouter.get('/missions', adminController.getMissions);
adminRouter.post('/missions', adminController.createMission);
adminRouter.put('/missions/:id', idParamValidator, validate, adminController.updateMission);
adminRouter.delete('/missions/:id', idParamValidator, validate, adminController.deleteMission);

// Badge management
adminRouter.get('/badges', adminController.getBadges);
adminRouter.post('/badges', adminController.createBadge);
adminRouter.put('/badges/:id', idParamValidator, validate, adminController.updateBadge);
adminRouter.delete('/badges/:id', idParamValidator, validate, adminController.deleteBadge);

// Library management
adminRouter.get('/library', adminController.getLibraryItems);
adminRouter.post('/library', adminController.createLibraryItem);
adminRouter.put('/library/:id', idParamValidator, validate, adminController.updateLibraryItem);
adminRouter.delete('/library/:id', idParamValidator, validate, adminController.deleteLibraryItem);

// Game question management
adminRouter.get('/game-questions', adminController.getGameQuestions);
adminRouter.post('/game-questions', adminController.createGameQuestion);
adminRouter.put('/game-questions/:id', idParamValidator, validate, adminController.updateGameQuestion);
adminRouter.delete('/game-questions/:id', idParamValidator, validate, adminController.deleteGameQuestion);

// Test question management
adminRouter.get('/test-questions', adminController.getTestQuestions);
adminRouter.post('/test-questions', adminController.createTestQuestion);
adminRouter.put('/test-questions/:id', idParamValidator, validate, adminController.updateTestQuestion);
adminRouter.delete('/test-questions/:id', idParamValidator, validate, adminController.deleteTestQuestion);

// Notification management
adminRouter.get('/notifications', adminController.getNotifications);
adminRouter.post('/notifications', adminController.createNotification);
adminRouter.delete('/notifications/:id', idParamValidator, validate, adminController.deleteNotification);

module.exports = {
  gameRouter,
  missionRouter,
  badgeRouter,
  achievementRouter,
  rankRouter,
  uploadRouter,
  adminRouter,
  libraryRouter,
};
