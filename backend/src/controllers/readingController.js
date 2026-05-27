/**
 * ========================================
 * Reading Controller
 * ========================================
 */

const readingService = require('../services/readingService');
const { sendSuccess } = require('../utils/response');
const { MESSAGES } = require('../constants');

class ReadingController {
  /** GET /api/reading/lessons */
  async getLessons(req, res, next) {
    try {
      const lessons = await readingService.getReadingLessons(req.query);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, lessons);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/reading/result */
  async saveResult(req, res, next) {
    try {
      const io = req.app.get('io');
      const result = await readingService.saveResult(req.user._id, req.body, io);
      sendSuccess(res, MESSAGES.RESULT_SAVED, result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReadingController();
