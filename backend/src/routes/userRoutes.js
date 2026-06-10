/**
 * ========================================
 * User Routes
 * ========================================
 * 
 * GET  /api/users/profile
 * PUT  /api/users/profile
 * GET  /api/users/rank
 */

const router = require('express').Router();
const userController = require('../controllers/userController');
const gamePlaySessionController = require('../controllers/gamePlaySessionController');
const { authenticate } = require('../middlewares/auth');
const { validate } = require('../middlewares/validate');
const { updateProfileValidator } = require('../validators');

// All routes require authentication
router.use(authenticate);

router.get('/profile', userController.getProfile);
router.put('/profile', updateProfileValidator, validate, userController.updateProfile);
router.get('/rank', userController.getUserRank);

// Accumulate Stars & XP APIs (Gamified Reward System)
router.post('/accumulate-stars', gamePlaySessionController.accumulateStars);
router.post('/accumulate-xp', gamePlaySessionController.accumulateXP);

module.exports = router;
