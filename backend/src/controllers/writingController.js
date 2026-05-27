/**
 * ========================================
 * Writing Controller
 * ========================================
 */

const writingService = require('../services/writingService');
const { sendSuccess } = require('../utils/response');
const { MESSAGES } = require('../constants');

class WritingController {
  /** POST /api/writing/check */
  async checkWriting(req, res, next) {
    try {
      const io = req.app.get('io');
      const result = await writingService.checkWriting(req.user._id, req.body, io);
      sendSuccess(res, MESSAGES.RESULT_SAVED, result);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/writing/save */
  async saveResult(req, res, next) {
    try {
      const result = await writingService.saveResult(req.user._id, req.body);
      sendSuccess(res, MESSAGES.RESULT_SAVED, result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new WritingController();
