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

// Public route for testing reminder pushes
router.get('/test-send-public', async (req, res, next) => {
  try {
    const User = require('../models/User');
    const user = await User.findOne({ role: 'user' });
    if (!user) {
      return res.status(404).json({ success: false, message: 'No user found' });
    }

    const Notification = require('../models/Notification');
    const { NOTIFICATION_TYPES, SOCKET_EVENTS } = require('../constants');
    const { emitToUser } = require('../sockets');

    // Sample messages
    const REMINDER_MESSAGES = [
      { id: 'msg1', title: '🥹 Bé ơi...', message: 'Bài học nhớ bé quá rồi nè...' },
      { id: 'msg2', title: '🐘 Bạn Voi con', message: 'Voi con đang đợi học cùng bé đó!' },
      { id: 'msg3', title: '🌟 Sao lấp lánh', message: 'Chỉ 5 phút học thôi, bé sẽ nhận được thật nhiều sao đó!' },
      { id: 'msg4', title: '💕 Mình học nhé', message: 'Bé nghỉ đủ rồi, mình học cùng nhau nha!' },
      { id: 'msg5', title: '🎈 Bắt đầu lại nào', message: 'Không sao nếu hôm qua quên học, hôm nay mình bắt đầu lại nhé!' },
      { id: 'msg6', title: '🍀 Siêu anh hùng', message: 'Mỗi ngày học một chút, bé sẽ trở thành siêu anh hùng đó!' },
      { id: 'msg7', title: '🥰 Vui quá đi', message: 'Bé xuất hiện là bài học vui hẳn lên luôn!' },
      { id: 'msg8', title: '🌞 Chào buổi sáng', message: 'Chào buổi sáng! Đến lúc khám phá điều mới rồi bé ơi!' },
      { id: 'msg9', title: '🎁 Quà bất ngờ', message: 'Hoàn thành bài học hôm nay để nhận quà bất ngờ nha!' },
      { id: 'msg10', title: '🚀 Sẵn sàng chưa?', message: 'Cuộc phiêu lưu học tập đang chờ bé đó! ✨' }
    ];

    const selectedMsg = REMINDER_MESSAGES[Math.floor(Math.random() * REMINDER_MESSAGES.length)];

    const notification = await Notification.create({
      userId: user._id,
      title: `${selectedMsg.title}`,
      message: selectedMsg.message,
      type: NOTIFICATION_TYPES.STUDY_REMINDER,
      reminderType: 'daily_first',
      isRead: false
    });

    emitToUser(user._id, SOCKET_EVENTS.NOTIFICATION, notification);

    // Phát quảng bá (broadcast) để tất cả các tài khoản đang kết nối đều nhận được
    const { broadcast } = require('../sockets');
    broadcast(SOCKET_EVENTS.NOTIFICATION, notification);

    res.status(200).json({ success: true, message: `Sent and broadcasted test notification`, notification });
  } catch (error) {
    next(error);
  }
});

// Tất cả routes tiếp theo yêu cầu đăng nhập
router.use(authenticate);

router.get('/', notificationController.getNotifications);
router.put('/read-all', notificationController.markAllAsRead);
router.post('/test-reminder', notificationController.sendTestReminder);
router.put('/:id/read', idParamValidator, validate, notificationController.markAsRead);

module.exports = router;
