/**
 * ========================================
 * Listening Controller
 * ========================================
 */

const listeningService = require('../services/listeningService');
const { sendSuccess } = require('../utils/response');
const { MESSAGES } = require('../constants');

class ListeningController {
  /** GET /api/listening/lessons */
  async getLessons(req, res, next) {
    try {
      const lessons = await listeningService.getListeningLessons(req.query);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, lessons);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/listening/result */
  async saveResult(req, res, next) {
    try {
      const io = req.app.get('io');
      const result = await listeningService.saveResult(req.user._id, req.body, io);
      sendSuccess(res, MESSAGES.RESULT_SAVED, result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ListeningController();
