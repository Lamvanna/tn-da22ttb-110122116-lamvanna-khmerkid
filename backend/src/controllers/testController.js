/**
 * ========================================
 * Test Controller
 * ========================================
 */

const TestQuestion = require('../models/TestQuestion');
const { sendSuccess } = require('../utils/response');
const { MESSAGES } = require('../constants');

class TestController {
  /** GET /api/tests/questions */
  async getQuestions(req, res, next) {
    try {
      const filter = { isActive: true };
      if (req.query.testRange) {
        filter.testRange = req.query.testRange;
      }
      
      const questions = await TestQuestion.find(filter).sort({ createdAt: -1 });
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, questions);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new TestController();
