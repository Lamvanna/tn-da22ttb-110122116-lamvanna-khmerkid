/**
 * ========================================
 * Notification Controller (Student/User)
 * ========================================
 */

const Notification = require('../models/Notification');
const { sendSuccess, sendError } = require('../utils/response');
const { MESSAGES } = require('../constants');

class NotificationController {
  /**
   * GET /api/notifications
   * Fetch all notifications for the current authenticated user
   */
  async getNotifications(req, res, next) {
    try {
      const userId = req.user.id;
      
      const notifications = await Notification.find({ userId })
        .sort({ createdAt: -1 })
        .lean();

      sendSuccess(res, MESSAGES.FETCH_SUCCESS, notifications);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/notifications/:id/read
   * Mark a specific notification as read
   */
  async markAsRead(req, res, next) {
    try {
      const userId = req.user.id;
      const notificationId = req.params.id;

      const notification = await Notification.findOneAndUpdate(
        { _id: notificationId, userId },
        { isRead: true },
        { new: true }
      );

      if (!notification) {
        return sendError(res, MESSAGES.NOT_FOUND, 404);
      }

      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, { notification });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/notifications/read-all
   * Mark all notifications for the current user as read
   */
  async markAllAsRead(req, res, next) {
    try {
      const userId = req.user.id;

      await Notification.updateMany(
        { userId, isRead: false },
        { isRead: true }
      );

      sendSuccess(res, MESSAGES.UPDATE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/notifications/test-reminder
   * Trigger a test study reminder notification for the current user immediately
   */
  async sendTestReminder(req, res, next) {
    try {
      const user = await require('../models/User').findById(req.user.id);
      if (!user) {
        return sendError(res, MESSAGES.USER_NOT_FOUND, 404);
      }

      // Import the study reminder service and select a random message
      const studyReminderService = require('../services/studyReminderService');
      const Notification = require('../models/Notification');
      const { NOTIFICATION_TYPES, SOCKET_EVENTS } = require('../constants');
      const { emitToUser } = require('../sockets');

      // Check last notifications to avoid repeating the last 3
      const recentNotifications = await Notification.find({
        userId: user._id,
        reminderType: { $ne: null }
      })
        .sort({ createdAt: -1 })
        .limit(3)
        .lean();

      const recentMessages = recentNotifications.map(n => n.message);
      
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

      const availableMessages = REMINDER_MESSAGES.filter(
        item => !recentMessages.includes(item.message)
      );

      const choices = availableMessages.length > 0 ? availableMessages : REMINDER_MESSAGES;
      const selectedMsg = choices[Math.floor(Math.random() * choices.length)];

      // Create notification
      const notification = await Notification.create({
        userId: user._id,
        title: `[TEST] ${selectedMsg.title}`,
        message: selectedMsg.message,
        type: NOTIFICATION_TYPES.STUDY_REMINDER,
        reminderType: 'daily_first',
        isRead: false
      });

      // Emit to socket
      emitToUser(user._id, SOCKET_EVENTS.NOTIFICATION, notification);

      sendSuccess(res, 'Gửi thông báo test thành công!', notification);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new NotificationController();
