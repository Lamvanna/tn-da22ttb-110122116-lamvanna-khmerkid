/**
 * ========================================
 * Notification Routes
 * ========================================
 * 
 * GET    /api/notifications           — lấy thông báo của người dùng
 * PUT    /api/notifications/:id/read  — đánh dấu đã đọc
 * PUT    /api/notifications/read-all  — đánh dấu đã đọc tất cả
 */

const router = require('express').Router();
const notificationController = require('../controllers/notificationController');
const { authenticate } = require('../middlewares/auth');
const { idParamValidator } = require('../validators');
const { validate } = require('../middlewares/validate');

// Tất cả routes yêu cầu đăng nhập
router.use(authenticate);

router.get('/', notificationController.getNotifications);
router.put('/read-all', notificationController.markAllAsRead);
router.put('/:id/read', idParamValidator, validate, notificationController.markAsRead);

module.exports = router;
