/**
 * ========================================
 * Library Controller (User-facing)
 * ========================================
 */

const LibraryItem = require('../models/LibraryItem');
const { paginateQuery } = require('../utils/pagination');
const { MESSAGES } = require('../constants');

class LibraryController {
  /** GET /api/library */
  async getLibraryItems(req, res, next) {
    try {
      const filter = { isActive: true };
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
}

module.exports = new LibraryController();
