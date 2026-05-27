/**
 * ========================================
 * Pagination Helper
 * ========================================
 * 
 * Reusable pagination for Mongoose queries.
 */

/**
 * Parse pagination parameters from query
 * @param {Object} query - Express req.query
 * @returns {Object} { page, limit, skip }
 */
const parsePagination = (query) => {
  const page = Math.max(1, parseInt(query.page) || 1);
  const limit = Math.min(50, Math.max(1, parseInt(query.limit) || 10));
  const skip = (page - 1) * limit;

  return { page, limit, skip };
};

/**
 * Create pagination result object
 * @param {number} totalDocs - Total number of documents
 * @param {number} page - Current page
 * @param {number} limit - Items per page
 * @returns {Object} Pagination metadata
 */
const createPaginationResult = (totalDocs, page, limit) => {
  const totalPages = Math.ceil(totalDocs / limit);

  return {
    currentPage: page,
    totalPages,
    totalDocs,
    limit,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1,
  };
};

/**
 * Execute paginated query
 * @param {Object} Model - Mongoose model
 * @param {Object} filter - Query filter
 * @param {Object} options - { page, limit, sort, populate, select }
 * @returns {Object} { data, pagination }
 */
const paginateQuery = async (Model, filter = {}, options = {}) => {
  const { page, limit, skip } = parsePagination(options);
  const sort = options.sort || { createdAt: -1 };

  const [data, totalDocs] = await Promise.all([
    Model.find(filter)
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .populate(options.populate || '')
      .select(options.select || '')
      .lean(),
    Model.countDocuments(filter),
  ]);

  const pagination = createPaginationResult(totalDocs, page, limit);

  return { data, pagination };
};

module.exports = {
  parsePagination,
  createPaginationResult,
  paginateQuery,
};
