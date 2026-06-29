/**
 * ========================================
 * Progress Routes
 * ========================================
 * 
 * GET    /api/progress/get         — lấy progress hiện tại
 * POST   /api/progress/sync        — đồng bộ 2 chiều
 * POST   /api/progress/complete    — hoàn thành bài học
 * POST   /api/progress/unlock      — mở khóa bài học
 */

const router = require('express').Router();
const progressController = require('../controllers/progressController');
const { authenticate } = require('../middlewares/auth');

// Tất cả routes đều yêu cầu auth
router.use(authenticate);

router.get('/get', progressController.getProgress);
router.post('/sync', progressController.syncProgress);
router.post('/complete', progressController.completeLesson);
router.post('/unlock', progressController.unlockLesson);

module.exports = router;
