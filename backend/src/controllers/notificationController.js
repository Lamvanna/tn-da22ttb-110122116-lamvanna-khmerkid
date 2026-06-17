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
}

module.exports = new NotificationController();
