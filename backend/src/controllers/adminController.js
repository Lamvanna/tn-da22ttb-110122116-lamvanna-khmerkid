/**
 * ========================================
 * Admin Controller
 * ========================================
 */

const User = require('../models/User');
const Lesson = require('../models/Lesson');
const Badge = require('../models/Badge');
const Mission = require('../models/Mission');
const GameResult = require('../models/GameResult');
const SpeakingResult = require('../models/SpeakingResult');
const ListeningResult = require('../models/ListeningResult');
const { sendSuccess } = require('../utils/response');
const { MESSAGES } = require('../constants');
const { paginateQuery } = require('../utils/pagination');

class AdminController {
  /** GET /api/admin/dashboard */
  async getDashboard(req, res, next) {
    try {
      const [totalUsers, totalLessons, totalBadges, totalGames] = await Promise.all([
        User.countDocuments(),
        Lesson.countDocuments({ isActive: true }),
        Badge.countDocuments({ isActive: true }),
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

  /** GET /api/admin/users */
  async getUsers(req, res, next) {
    try {
      const { data, pagination } = await paginateQuery(User, {}, {
        page: req.query.page,
        limit: req.query.limit,
        sort: { createdAt: -1 },
        select: 'name email role level xp stars streak createdAt lastLoginDate',
      });
      res.status(200).json({ success: true, message: MESSAGES.FETCH_SUCCESS, data, pagination });
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/admin/users/:id */
  async deleteUser(req, res, next) {
    try {
      const user = await User.findByIdAndDelete(req.params.id);
      if (!user) return res.status(404).json({ success: false, message: MESSAGES.USER_NOT_FOUND });
      sendSuccess(res, MESSAGES.DELETE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AdminController();
