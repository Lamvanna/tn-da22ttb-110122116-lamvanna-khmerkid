/**
 * ========================================
 * Progress Controller
 * ========================================
 * 
 * REST handlers for progress sync API.
 */

const progressService = require('../services/progressService');
const { sendSuccess } = require('../utils/response');

class ProgressController {
  /** GET /api/progress/get */
  async getProgress(req, res, next) {
    try {
      const data = await progressService.getProgress(req.user.id);
      sendSuccess(res, 'Lấy tiến độ thành công!', data);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/progress/sync */
  async syncProgress(req, res, next) {
    try {
      const data = await progressService.syncProgress(req.user.id, req.body);
      sendSuccess(res, 'Đồng bộ tiến độ thành công!', data);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/progress/complete */
  async completeLesson(req, res, next) {
    try {
      const { lessonId, stars, lessonType } = req.body;

      if (!lessonId) {
        return res.status(400).json({
          success: false,
          message: 'lessonId là bắt buộc!',
        });
      }

      const data = await progressService.completeLesson(
        req.user.id,
        lessonId,
        stars || 0,
        lessonType || ''
      );
      sendSuccess(res, 'Hoàn thành bài học thành công!', data);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/progress/unlock */
  async unlockLesson(req, res, next) {
    try {
      const { lessonId } = req.body;

      if (!lessonId) {
        return res.status(400).json({
          success: false,
          message: 'lessonId là bắt buộc!',
        });
      }

      const data = await progressService.unlockLesson(req.user.id, lessonId);
      sendSuccess(res, 'Mở khóa bài học thành công!', data);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ProgressController();
