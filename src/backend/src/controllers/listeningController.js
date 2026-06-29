const fs = require('fs');
const path = require('path');
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
      const logPath = path.join(__dirname, '../../debug.log');
      fs.appendFileSync(logPath, `[${new Date().toISOString()}] PAYLOAD: ${JSON.stringify(req.body)}\n`);
      
      const io = req.app.get('io');
      const result = await listeningService.saveResult(req.user._id, req.body, io);
      
      fs.appendFileSync(logPath, `[${new Date().toISOString()}] RESULT: ${JSON.stringify(result)}\n`);
      
      sendSuccess(res, MESSAGES.RESULT_SAVED, result);
    } catch (error) {
      const logPath = path.join(__dirname, '../../debug.log');
      fs.appendFileSync(logPath, `[${new Date().toISOString()}] ERROR: ${error.message}\n`);
      next(error);
    }
  }
}

module.exports = new ListeningController();
