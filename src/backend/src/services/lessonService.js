/**
 * ========================================
 * Lesson Service
 * ========================================
 * 
 * CRUD operations and filtering for lessons.
 */

const Lesson = require('../models/Lesson');
const { paginateQuery } = require('../utils/pagination');
const { AppError } = require('../middlewares/errorHandler');
const { MESSAGES } = require('../constants');

class LessonService {
  /**
   * Get all lessons with filters and pagination
   */
  async getLessons(query = {}) {
    const filter = { isActive: true };

    // Apply filters
    if (query.type) filter.type = query.type;
    if (query.difficulty) filter.difficulty = query.difficulty;
    if (query.category) filter.category = query.category;

    const options = {
      page: query.page,
      limit: query.limit,
      sort: { order: 1, createdAt: 1 },
    };

    return await paginateQuery(Lesson, filter, options);
  }

  /**
   * Get single lesson by ID
   */
  async getLessonById(lessonId) {
    const mongoose = require('mongoose');
    if (!mongoose.Types.ObjectId.isValid(lessonId)) {
      throw new AppError(MESSAGES.NOT_FOUND, 404);
    }

    const lesson = await Lesson.findById(lessonId);

    if (!lesson) {
      throw new AppError(MESSAGES.NOT_FOUND, 404);
    }

    return lesson;
  }

  /**
   * Get lessons by type
   */
  async getLessonsByType(type, query = {}) {
    const filter = { type, isActive: true };

    if (query.difficulty) filter.difficulty = query.difficulty;

    const options = {
      page: query.page,
      limit: query.limit || 50,
      sort: { order: 1 },
    };

    return await paginateQuery(Lesson, filter, options);
  }

  /**
   * Create a new lesson (Admin)
   */
  async createLesson(lessonData) {
    const lesson = await Lesson.create(lessonData);
    return lesson;
  }

  /**
   * Update a lesson (Admin)
   */
  async updateLesson(lessonId, updateData) {
    const lesson = await Lesson.findByIdAndUpdate(lessonId, updateData, {
      new: true,
      runValidators: true,
    });

    if (!lesson) {
      throw new AppError(MESSAGES.NOT_FOUND, 404);
    }

    return lesson;
  }

  /**
   * Delete a lesson (Admin) - soft delete
   */
  async deleteLesson(lessonId) {
    const lesson = await Lesson.findByIdAndUpdate(
      lessonId,
      { isActive: false },
      { new: true }
    );

    if (!lesson) {
      throw new AppError(MESSAGES.NOT_FOUND, 404);
    }

    return lesson;
  }

  /**
   * Get lesson count by type
   */
  async getLessonStats() {
    const stats = await Lesson.aggregate([
      { $match: { isActive: true } },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
        },
      },
    ]);

    return stats;
  }
}

module.exports = new LessonService();
