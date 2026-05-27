/**
 * ========================================
 * User Controller
 * ========================================
 */

const userService = require('../services/userService');
const { sendSuccess } = require('../utils/response');
const { MESSAGES } = require('../constants');

class UserController {
  /** GET /api/users/profile */
  async getProfile(req, res, next) {
    try {
      const profile = await userService.getProfile(req.user._id);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, profile);
    } catch (error) {
      next(error);
    }
  }

  /** PUT /api/users/profile */
  async updateProfile(req, res, next) {
    try {
      const user = await userService.updateProfile(req.user._id, req.body);
      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, user);
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/users/rank */
  async getUserRank(req, res, next) {
    try {
      const rank = await userService.getUserRank(req.user._id);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, rank);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UserController();
