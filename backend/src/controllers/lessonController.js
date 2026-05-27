/**
 * ========================================
 * Lesson Controller
 * ========================================
 */

const lessonService = require('../services/lessonService');
const { sendSuccess, sendCreated } = require('../utils/response');
const { MESSAGES } = require('../constants');

class LessonController {
  /** GET /api/lessons */
  async getLessons(req, res, next) {
    try {
      const { data, pagination } = await lessonService.getLessons(req.query);
      res.status(200).json({
        success: true,
        message: MESSAGES.FETCH_SUCCESS,
        data,
        pagination,
      });
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/lessons/:id */
  async getLessonById(req, res, next) {
    try {
      const lesson = await lessonService.getLessonById(req.params.id);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, lesson);
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/lessons/type/:type */
  async getLessonsByType(req, res, next) {
    try {
      const { data, pagination } = await lessonService.getLessonsByType(
        req.params.type,
        req.query
      );
      res.status(200).json({
        success: true,
        message: MESSAGES.FETCH_SUCCESS,
        data,
        pagination,
      });
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/lessons */
  async createLesson(req, res, next) {
    try {
      const lesson = await lessonService.createLesson(req.body);
      sendCreated(res, MESSAGES.CREATE_SUCCESS, lesson);
    } catch (error) {
      next(error);
    }
  }

  /** PUT /api/lessons/:id */
  async updateLesson(req, res, next) {
    try {
      const lesson = await lessonService.updateLesson(req.params.id, req.body);
      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, lesson);
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/lessons/:id */
  async deleteLesson(req, res, next) {
    try {
      await lessonService.deleteLesson(req.params.id);
      sendSuccess(res, MESSAGES.DELETE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new LessonController();
