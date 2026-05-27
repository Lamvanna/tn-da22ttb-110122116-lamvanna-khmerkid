/**
 * ========================================
 * General Helper Utilities
 * ========================================
 * 
 * Common utility functions used across
 * the application.
 */

const { XP_CONFIG, STARS_CONFIG } = require('../constants');

/**
 * Calculate XP needed for a specific level
 * Formula: base * multiplier^(level-1)
 * @param {number} level - Target level
 * @returns {number} XP needed
 */
const xpForLevel = (level) => {
  return Math.floor(
    XP_CONFIG.LEVEL_UP_BASE * Math.pow(XP_CONFIG.LEVEL_UP_MULTIPLIER, level - 1)
  );
};

/**
 * Calculate total XP needed from level 1 to target level
 * @param {number} targetLevel - Target level
 * @returns {number} Total cumulative XP
 */
const totalXpForLevel = (targetLevel) => {
  let total = 0;
  for (let i = 1; i < targetLevel; i++) {
    total += xpForLevel(i);
  }
  return total;
};

/**
 * Calculate level from total XP
 * @param {number} totalXp - Total XP earned
 * @returns {Object} { level, currentLevelXp, nextLevelXp, progress }
 */
const calculateLevel = (totalXp) => {
  let level = 1;
  let remainingXp = totalXp;

  while (remainingXp >= xpForLevel(level)) {
    remainingXp -= xpForLevel(level);
    level++;
  }

  const nextLevelXp = xpForLevel(level);
  const progress = Math.round((remainingXp / nextLevelXp) * 100);

  return {
    level,
    currentLevelXp: remainingXp,
    nextLevelXp,
    progress,
  };
};

/**
 * Calculate stars from accuracy/score percentage
 * @param {number} percentage - Score percentage (0-100)
 * @returns {number} Stars earned (0-3)
 */
const calculateStars = (percentage) => {
  if (percentage >= STARS_CONFIG.THREE_STARS) return 3;
  if (percentage >= STARS_CONFIG.TWO_STARS) return 2;
  if (percentage >= STARS_CONFIG.ONE_STAR) return 1;
  return 0;
};

/**
 * Check if score passes the threshold
 * @param {number} score - Score percentage
 * @returns {boolean} Whether the score passes
 */
const isPassed = (score) => {
  return score >= STARS_CONFIG.PASS_THRESHOLD;
};

/**
 * Calculate streak from dates
 * @param {Date} lastLogin - Last login date
 * @param {Date} now - Current date
 * @param {number} currentStreak - Current streak count
 * @returns {Object} { streak, isNewDay }
 */
const calculateStreak = (lastLogin, now = new Date(), currentStreak = 0) => {
  if (!lastLogin) {
    return { streak: 1, isNewDay: true };
  }

  const lastDate = new Date(lastLogin);
  const today = new Date(now);

  // Reset time to compare dates only
  lastDate.setHours(0, 0, 0, 0);
  today.setHours(0, 0, 0, 0);

  const diffTime = today.getTime() - lastDate.getTime();
  const diffDays = diffTime / (1000 * 60 * 60 * 24);

  if (diffDays === 0) {
    // Same day - no streak change
    return { streak: currentStreak, isNewDay: false };
  } else if (diffDays === 1) {
    // Consecutive day - increment streak
    return { streak: currentStreak + 1, isNewDay: true };
  } else {
    // Streak broken - reset to 1
    return { streak: 1, isNewDay: true };
  }
};

/**
 * Slugify a string
 * @param {string} text - Input text
 * @returns {string} Slugified text
 */
const slugify = (text) => {
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/[^\w\-]+/g, '')
    .replace(/\-\-+/g, '-');
};

/**
 * Get start and end of current day (UTC)
 * @returns {Object} { startOfDay, endOfDay }
 */
const getTodayRange = () => {
  const now = new Date();
  const startOfDay = new Date(now.setHours(0, 0, 0, 0));
  const endOfDay = new Date(now.setHours(23, 59, 59, 999));
  return { startOfDay, endOfDay };
};

/**
 * Get start of current week (Monday)
 * @returns {Date} Start of week
 */
const getStartOfWeek = () => {
  const now = new Date();
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? -6 : 1);
  const startOfWeek = new Date(now.setDate(diff));
  startOfWeek.setHours(0, 0, 0, 0);
  return startOfWeek;
};

/**
 * Get start of current month
 * @returns {Date} Start of month
 */
const getStartOfMonth = () => {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), 1);
};

/**
 * Sanitize user input - remove HTML tags
 * @param {string} str - Input string
 * @returns {string} Sanitized string
 */
const sanitizeInput = (str) => {
  if (typeof str !== 'string') return str;
  return str.replace(/<[^>]*>/g, '').trim();
};

/**
 * Generate random string
 * @param {number} length - String length
 * @returns {string} Random string
 */
const generateRandomString = (length = 32) => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

module.exports = {
  xpForLevel,
  totalXpForLevel,
  calculateLevel,
  calculateStars,
  isPassed,
  calculateStreak,
  slugify,
  getTodayRange,
  getStartOfWeek,
  getStartOfMonth,
  sanitizeInput,
  generateRandomString,
};
