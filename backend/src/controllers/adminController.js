/**
 * ========================================
 * Admin Controller
 * ========================================
 * 
 * Full admin panel: Dashboard, Statistics,
 * CRUD Users, Lessons, Missions, Badges.
 */

const User = require('../models/User');
const Lesson = require('../models/Lesson');
const Badge = require('../models/Badge');
const Mission = require('../models/Mission');
const GameResult = require('../models/GameResult');
const ListeningResult = require('../models/ListeningResult');
const LibraryItem = require('../models/LibraryItem');
const GameQuestion = require('../models/GameQuestion');
const TestQuestion = require('../models/TestQuestion');
const { sendSuccess, sendError } = require('../utils/response');
const { MESSAGES } = require('../constants');
const { paginateQuery } = require('../utils/pagination');

class AdminController {
  // ========================================
  // Dashboard & Statistics
  // ========================================

  /** GET /api/admin/dashboard */
  async getDashboard(req, res, next) {
    try {
      const [totalUsers, totalLessons, totalBadges, totalMissions, totalGames] = await Promise.all([
        User.countDocuments(),
        Lesson.countDocuments({ isActive: true }),
        Badge.countDocuments({ isActive: true }),
        Mission.countDocuments({ isActive: true }),
        GameResult.countDocuments(),
      ]);

      // Recent signups (last 7 days)
      const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const recentSignups = await User.countDocuments({ createdAt: { $gte: weekAgo } });

      // Active users today
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const activeToday = await User.countDocuments({ lastActiveDate: { $gte: today } });

      sendSuccess(res, MESSAGES.FETCH_SUCCESS, {
        totalUsers,
        totalLessons,
        totalBadges,
        totalMissions,
        totalGames,
        recentSignups,
        activeToday,
      });
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/admin/statistics */
  async getStatistics(req, res, next) {
    try {
      // Lesson stats by type
      const lessonStats = await Lesson.aggregate([
        { $match: { isActive: true } },
        { $group: { _id: '$type', count: { $sum: 1 } } },
      ]);

      // Top users by XP
      const topUsers = await User.find()
        .select('name email level xp stars streak')
        .sort({ xp: -1 })
        .limit(10)
        .lean();

      // Daily activity (last 7 days)
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const dailyActivity = await GameResult.aggregate([
        { $match: { createdAt: { $gte: sevenDaysAgo } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            count: { $sum: 1 },
            totalXp: { $sum: '$xpEarned' },
          },
        },
        { $sort: { _id: 1 } },
      ]);

      sendSuccess(res, MESSAGES.FETCH_SUCCESS, {
        lessonStats,
        topUsers,
        dailyActivity,
      });
    } catch (error) {
      next(error);
    }
  }

  // ========================================
  // User Management
  // ========================================

  /** GET /api/admin/users */
  async getUsers(req, res, next) {
    try {
      // Build filter from query params
      const filter = {};
      if (req.query.search) {
        const searchRegex = new RegExp(req.query.search, 'i');
        filter.$or = [
          { name: searchRegex },
          { email: searchRegex },
        ];
      }
      if (req.query.role) {
        filter.role = req.query.role;
      }

      const { data, pagination } = await paginateQuery(User, filter, {
        page: req.query.page,
        limit: req.query.limit,
        sort: { createdAt: -1 },
        select: 'name email role level xp stars streak avatar createdAt lastLoginDate lastActiveDate',
      });
      res.status(200).json({ success: true, message: MESSAGES.FETCH_SUCCESS, data, pagination });
    } catch (error) {
      next(error);
    }
  }

  /** PUT /api/admin/users/:id/role */
  async updateUserRole(req, res, next) {
    try {
      const { role } = req.body;
      if (!['user', 'admin'].includes(role)) {
        return sendError(res, 'Role không hợp lệ (user hoặc admin)', 400);
      }

      // Prevent admin from changing their own role
      if (req.params.id === req.user._id.toString()) {
        return sendError(res, 'Không thể thay đổi role của chính mình', 400);
      }

      const user = await User.findByIdAndUpdate(
        req.params.id,
        { role },
        { new: true, runValidators: true }
      ).select('name email role');

      if (!user) return sendError(res, MESSAGES.USER_NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, { user });
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/admin/users/:id */
  async deleteUser(req, res, next) {
    try {
      // Prevent admin from deleting themselves
      if (req.params.id === req.user._id.toString()) {
        return sendError(res, 'Không thể xóa chính mình', 400);
      }

      const user = await User.findByIdAndDelete(req.params.id);
      if (!user) return sendError(res, MESSAGES.USER_NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.DELETE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }

  // ========================================
  // Lesson Management
  // ========================================

  /** GET /api/admin/lessons */
  async getLessons(req, res, next) {
    try {
      const filter = {};
      if (req.query.type) filter.type = req.query.type;
      if (req.query.difficulty) filter.difficulty = req.query.difficulty;
      if (req.query.search) {
        filter.title = new RegExp(req.query.search, 'i');
      }

      const { data, pagination } = await paginateQuery(Lesson, filter, {
        page: req.query.page,
        limit: req.query.limit,
        sort: { type: 1, order: 1 },
        select: 'title type khmerText romanized meaning difficulty order isActive category createdAt',
      });
      res.status(200).json({ success: true, message: MESSAGES.FETCH_SUCCESS, data, pagination });
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/admin/lessons */
  async createLesson(req, res, next) {
    try {
      const lesson = await Lesson.create(req.body);
      sendSuccess(res, MESSAGES.CREATE_SUCCESS, { lesson }, 201);
    } catch (error) {
      next(error);
    }
  }

  /** PUT /api/admin/lessons/:id */
  async updateLesson(req, res, next) {
    try {
      const lesson = await Lesson.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true, runValidators: true }
      );
      if (!lesson) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, { lesson });
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/admin/lessons/:id */
  async deleteLesson(req, res, next) {
    try {
      const lesson = await Lesson.findByIdAndDelete(req.params.id);
      if (!lesson) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.DELETE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }

  // ========================================
  // Mission Management
  // ========================================

  /** GET /api/admin/missions */
  async getMissions(req, res, next) {
    try {
      const filter = {};
      if (req.query.type) filter.type = req.query.type;
      if (req.query.search) {
        filter.title = new RegExp(req.query.search, 'i');
      }

      const { data, pagination } = await paginateQuery(Mission, filter, {
        page: req.query.page,
        limit: req.query.limit,
        sort: { order: 1 },
      });
      res.status(200).json({ success: true, message: MESSAGES.FETCH_SUCCESS, data, pagination });
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/admin/missions */
  async createMission(req, res, next) {
    try {
      const mission = await Mission.create(req.body);
      sendSuccess(res, MESSAGES.CREATE_SUCCESS, { mission }, 201);
    } catch (error) {
      next(error);
    }
  }

  /** PUT /api/admin/missions/:id */
  async updateMission(req, res, next) {
    try {
      const mission = await Mission.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true, runValidators: true }
      );
      if (!mission) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, { mission });
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/admin/missions/:id */
  async deleteMission(req, res, next) {
    try {
      const mission = await Mission.findByIdAndDelete(req.params.id);
      if (!mission) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.DELETE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }

  // ========================================
  // Badge Management
  // ========================================

  /** GET /api/admin/badges */
  async getBadges(req, res, next) {
    try {
      const filter = {};
      if (req.query.type) filter.type = req.query.type;
      if (req.query.search) {
        filter.name = new RegExp(req.query.search, 'i');
      }

      const { data, pagination } = await paginateQuery(Badge, filter, {
        page: req.query.page,
        limit: req.query.limit,
        sort: { order: 1 },
      });
      res.status(200).json({ success: true, message: MESSAGES.FETCH_SUCCESS, data, pagination });
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/admin/badges */
  async createBadge(req, res, next) {
    try {
      const badge = await Badge.create(req.body);
      sendSuccess(res, MESSAGES.CREATE_SUCCESS, { badge }, 201);
    } catch (error) {
      next(error);
    }
  }

  /** PUT /api/admin/badges/:id */
  async updateBadge(req, res, next) {
    try {
      const badge = await Badge.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true, runValidators: true }
      );
      if (!badge) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, { badge });
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/admin/badges/:id */
  async deleteBadge(req, res, next) {
    try {
      const badge = await Badge.findByIdAndDelete(req.params.id);
      if (!badge) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.DELETE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }

  // ========================================
  // Library Item Management
  // ========================================

  /** GET /api/admin/library */
  async getLibraryItems(req, res, next) {
    try {
      const filter = {};
      if (req.query.type) filter.type = req.query.type;
      if (req.query.search) {
        filter.title = new RegExp(req.query.search, 'i');
      }

      const { data, pagination } = await paginateQuery(LibraryItem, filter, {
        page: req.query.page,
        limit: req.query.limit,
        sort: { createdAt: -1 },
      });
      res.status(200).json({ success: true, message: MESSAGES.FETCH_SUCCESS, data, pagination });
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/admin/library */
  async createLibraryItem(req, res, next) {
    try {
      const libraryItem = await LibraryItem.create(req.body);
      sendSuccess(res, MESSAGES.CREATE_SUCCESS, { libraryItem }, 201);
    } catch (error) {
      next(error);
    }
  }

  /** PUT /api/admin/library/:id */
  async updateLibraryItem(req, res, next) {
    try {
      const libraryItem = await LibraryItem.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true, runValidators: true }
      );
      if (!libraryItem) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, { libraryItem });
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/admin/library/:id */
  async deleteLibraryItem(req, res, next) {
    try {
      const libraryItem = await LibraryItem.findByIdAndDelete(req.params.id);
      if (!libraryItem) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.DELETE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }

  // ========================================
  // Game Question Management
  // ========================================

  /** GET /api/admin/game-questions */
  async getGameQuestions(req, res, next) {
    try {
      const filter = {};
      if (req.query.gameKey) filter.gameKey = req.query.gameKey;
      if (req.query.search) {
        filter.title = new RegExp(req.query.search, 'i');
      }

      const { data, pagination } = await paginateQuery(GameQuestion, filter, {
        page: req.query.page,
        limit: req.query.limit,
        sort: { gameKey: 1, createdAt: -1 },
      });
      res.status(200).json({ success: true, message: MESSAGES.FETCH_SUCCESS, data, pagination });
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/admin/game-questions */
  async createGameQuestion(req, res, next) {
    try {
      const gameQuestion = await GameQuestion.create(req.body);
      sendSuccess(res, MESSAGES.CREATE_SUCCESS, { gameQuestion }, 201);
    } catch (error) {
      next(error);
    }
  }

  /** PUT /api/admin/game-questions/:id */
  async updateGameQuestion(req, res, next) {
    try {
      const gameQuestion = await GameQuestion.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true, runValidators: true }
      );
      if (!gameQuestion) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, { gameQuestion });
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/admin/game-questions/:id */
  async deleteGameQuestion(req, res, next) {
    try {
      const gameQuestion = await GameQuestion.findByIdAndDelete(req.params.id);
      if (!gameQuestion) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.DELETE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }

  // ========================================
  // Test Question Management
  // ========================================

  /** GET /api/admin/test-questions */
  async getTestQuestions(req, res, next) {
    try {
      const filter = {};
      if (req.query.testRange) filter.testRange = req.query.testRange;
      if (req.query.search) {
        filter.question = new RegExp(req.query.search, 'i');
      }

      const { data, pagination } = await paginateQuery(TestQuestion, filter, {
        page: req.query.page,
        limit: req.query.limit,
        sort: { testRange: 1, createdAt: -1 },
      });
      res.status(200).json({ success: true, message: MESSAGES.FETCH_SUCCESS, data, pagination });
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/admin/test-questions */
  async createTestQuestion(req, res, next) {
    try {
      const testQuestion = await TestQuestion.create(req.body);
      sendSuccess(res, MESSAGES.CREATE_SUCCESS, { testQuestion }, 201);
    } catch (error) {
      next(error);
    }
  }

  /** PUT /api/admin/test-questions/:id */
  async updateTestQuestion(req, res, next) {
    try {
      const testQuestion = await TestQuestion.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true, runValidators: true }
      );
      if (!testQuestion) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.UPDATE_SUCCESS, { testQuestion });
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/admin/test-questions/:id */
  async deleteTestQuestion(req, res, next) {
    try {
      const testQuestion = await TestQuestion.findByIdAndDelete(req.params.id);
      if (!testQuestion) return sendError(res, MESSAGES.NOT_FOUND, 404);
      sendSuccess(res, MESSAGES.DELETE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AdminController();
