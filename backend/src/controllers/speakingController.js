/**
 * ========================================
 * Speaking Controller
 * ========================================
 */

const speakingService = require('../services/speakingService');
const { sendSuccess } = require('../utils/response');
const { MESSAGES } = require('../constants');

class SpeakingController {
  /** POST /api/speaking/check */
  async checkPronunciation(req, res, next) {
    try {
      const io = req.app.get('io');
      const result = await speakingService.checkPronunciation(req.user._id, req.body, io);
      sendSuccess(res, MESSAGES.RESULT_SAVED, result);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/speaking/upload */
  async uploadAudio(req, res, next) {
    try {
      if (!req.file) {
        return res.status(400).json({ success: false, message: 'Không tìm thấy file audio!' });
      }

      const io = req.app.get('io');
      const result = await speakingService.checkPronunciation(req.user._id, {
        ...req.body,
        audioUrl: req.file.path,
        audioPublicId: req.file.filename,
      }, io);

      sendSuccess(res, MESSAGES.RESULT_SAVED, result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SpeakingController();
