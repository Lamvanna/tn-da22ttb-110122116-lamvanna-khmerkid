/**
 * ========================================
 * Route Aggregator
 * ========================================
 * 
 * Mounts all routes under /api prefix.
 */

const router = require('express').Router();

// Import routes
const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const lessonRoutes = require('./lessonRoutes');
const { listeningRouter, speakingRouter, writingRouter, readingRouter } = require('./skillRoutes');
const { gameRouter, missionRouter, badgeRouter, achievementRouter, rankRouter, uploadRouter, adminRouter } = require('./otherRoutes');

// ========================================
// Mount Routes
// ========================================
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/lessons', lessonRoutes);
router.use('/listening', listeningRouter);
router.use('/speaking', speakingRouter);
router.use('/writing', writingRouter);
router.use('/reading', readingRouter);
router.use('/games', gameRouter);
router.use('/missions', missionRouter);
router.use('/badges', badgeRouter);
router.use('/achievements', achievementRouter);
router.use('/rank', rankRouter);
router.use('/upload', uploadRouter);
router.use('/admin', adminRouter);

module.exports = router;
