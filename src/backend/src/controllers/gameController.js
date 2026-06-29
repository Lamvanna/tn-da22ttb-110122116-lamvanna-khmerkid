/**
 * ========================================
 * Game Controller
 * ========================================
 */

const gameService = require('../services/gameService');
const { sendSuccess } = require('../utils/response');
const { MESSAGES } = require('../constants');
const GameQuestion = require('../models/GameQuestion');

class GameController {
  /** POST /api/games/result */
  async saveResult(req, res, next) {
    try {
      const io = req.app.get('io');
      const result = await gameService.saveResult(req.user._id, req.body, io);
      sendSuccess(res, MESSAGES.RESULT_SAVED, result);
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/games/history */
  async getHistory(req, res, next) {
    try {
      const history = await gameService.getHistory(req.user._id, req.query);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, history);
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/games/questions */
  async getQuestions(req, res, next) {
    try {
      const filter = { isActive: true };
      if (req.query.gameKey) filter.gameKey = req.query.gameKey;
      
      const questions = await GameQuestion.find(filter).sort({ createdAt: -1 });
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, questions);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new GameController();
