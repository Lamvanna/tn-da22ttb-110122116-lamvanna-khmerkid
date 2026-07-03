/**
 * ========================================
 * Application Constants
 * ========================================
 * 
 * Centralized constants for roles, lesson types,
 * badge types, game types, skill levels, and messages.
 */

// ========================================
// User Roles
// ========================================
const ROLES = {
  USER: 'user',
  ADMIN: 'admin',
};

// ========================================
// Auth Providers
// ========================================
const AUTH_PROVIDERS = {
  LOCAL: 'local',
  GOOGLE: 'google',
};

// ========================================
// Lesson Types
// ========================================
const LESSON_TYPES = {
  CONSONANT: 'consonant',       // phụ âm
  VOWEL: 'vowel',               // nguyên âm
  CONSONANT_SERIES: 'consonant_series', // phụ âm o-ô
  DIACRITICAL: 'diacritical',   // học dấu
  SPELLING: 'spelling',         // ghép vần
  CLOSED_SYLLABLE: 'closed_syllable', // ghép vần đóng
  VOCABULARY: 'vocabulary',     // từ vựng
  SENTENCE: 'sentence',         // câu
  NUMBER: 'number',             // số
  COENG: 'coeng',               // chữ ghép
  READING: 'reading',           // tập đọc
  WRITING: 'writing',           // luyện viết
};

// ========================================
// Skill Types
// ========================================
const SKILL_TYPES = {
  LISTENING: 'listening',       // nghe
  SPEAKING: 'speaking',         // nói
  READING: 'reading',           // đọc
  WRITING: 'writing',           // viết
};

// ========================================
// Badge Types
// ========================================
const BADGE_TYPES = {
  LEVEL: 'level',               // huy hiệu cấp độ
  PRONUNCIATION: 'pronunciation', // huy hiệu phát âm
  STREAK: 'streak',             // huy hiệu chuỗi ngày
  LEARNING: 'learning',         // huy hiệu học tập
  RANKING: 'ranking',           // huy hiệu xếp hạng
};

// ========================================
// Game Types
// ========================================
const GAME_TYPES = {
  CATCH_LETTER: 'catch_letter',       // Bắt chữ Khmer
  MATCH_WORD: 'match_word',           // Nối từ
  LISTENING_QUIZ: 'listening_quiz',   // Trắc nghiệm nghe
  ARRANGE_LETTER: 'arrange_letter',   // Sắp xếp chữ
  PRONUNCIATION_QUIZ: 'pronunciation_quiz', // Trắc nghiệm phát âm
};

// ========================================
// Mission Types
// ========================================
const MISSION_TYPES = {
  DAILY: 'daily',
  WEEKLY: 'weekly',
};

// ========================================
// Mission Action Types
// ========================================
const MISSION_ACTIONS = {
  COMPLETE_LESSON: 'complete_lesson',     // Hoàn thành bài học
  LISTEN_LESSON: 'listen_lesson',         // Nghe bài
  SPEAK_LESSON: 'speak_lesson',           // Nói bài
  WRITE_LESSON: 'write_lesson',           // Viết bài
  PLAY_GAME: 'play_game',                 // Chơi game
  DAILY_LOGIN: 'daily_login',             // Đăng nhập hàng ngày
  READ_LESSON: 'read_lesson',             // Đọc bài
};

// ========================================
// Notification Types
// ========================================
const NOTIFICATION_TYPES = {
  DAILY_REMINDER: 'daily_reminder',
  STUDY_REMINDER: 'study_reminder',
  COMEBACK_REMINDER: 'comeback_reminder',
  REWARD: 'reward',
  BADGE_UNLOCKED: 'badge_unlocked',
  STREAK_UPDATE: 'streak_update',
  LEVEL_UP: 'level_up',
  RANK_UPDATE: 'rank_update',
  SYSTEM: 'system',
};

// ========================================
// Difficulty Levels
// ========================================
const DIFFICULTY = {
  BEGINNER: 'beginner',
  INTERMEDIATE: 'intermediate',
  ADVANCED: 'advanced',
};

// ========================================
// Ranking Periods
// ========================================
const RANKING_PERIODS = {
  GLOBAL: 'global',
  WEEKLY: 'weekly',
  MONTHLY: 'monthly',
};

// ========================================
// XP & Level Thresholds
// ========================================
const XP_CONFIG = {
  PER_LESSON: 10,               // XP cho mỗi bài học hoàn thành
  PER_GAME: 15,                 // XP cho mỗi game hoàn thành
  PER_SPEAKING: 20,             // XP cho speaking
  PER_WRITING: 15,              // XP cho writing
  PER_READING: 10,              // XP cho reading
  PER_LISTENING: 10,            // XP cho listening
  DAILY_LOGIN: 5,               // XP cho đăng nhập hàng ngày
  STREAK_BONUS: 2,              // XP bonus cho mỗi ngày streak
  LEVEL_UP_BASE: 100,           // XP cần cho level 1
  LEVEL_UP_MULTIPLIER: 1.5,    // Hệ số nhân cho mỗi level tiếp theo
};

// ========================================
// Stars Config
// ========================================
const STARS_CONFIG = {
  THREE_STARS: 90,   // >= 90% accuracy
  TWO_STARS: 70,     // >= 70% accuracy
  ONE_STAR: 50,      // >= 50% accuracy
  PASS_THRESHOLD: 70, // >= 70% to pass/unlock next
};

// ========================================
// Upload Config
// ========================================
const UPLOAD_CONFIG = {
  MAX_IMAGE_SIZE: 5 * 1024 * 1024,    // 5MB
  MAX_AUDIO_SIZE: 10 * 1024 * 1024,   // 10MB
  ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/webp'],
  ALLOWED_AUDIO_TYPES: ['audio/mpeg', 'audio/wav', 'audio/mp3', 'audio/x-wav'],
  IMAGE_FOLDER: 'khmerkid/images',
  AUDIO_FOLDER: 'khmerkid/audio',
};

// ========================================
// API Response Messages
// ========================================
const MESSAGES = {
  // Auth
  REGISTER_SUCCESS: 'Đăng ký thành công!',
  LOGIN_SUCCESS: 'Đăng nhập thành công!',
  LOGOUT_SUCCESS: 'Đăng xuất thành công!',
  TOKEN_REFRESHED: 'Token đã được làm mới!',
  INVALID_CREDENTIALS: 'Email hoặc mật khẩu không đúng!',
  EMAIL_EXISTS: 'Email đã được sử dụng!',
  USER_NOT_FOUND: 'Không tìm thấy người dùng!',
  TOKEN_INVALID: 'Token không hợp lệ!',
  TOKEN_EXPIRED: 'Token đã hết hạn!',
  UNAUTHORIZED: 'Bạn chưa đăng nhập!',
  FORBIDDEN: 'Bạn không có quyền truy cập!',

  // CRUD
  FETCH_SUCCESS: 'Lấy dữ liệu thành công!',
  CREATE_SUCCESS: 'Tạo thành công!',
  UPDATE_SUCCESS: 'Cập nhật thành công!',
  DELETE_SUCCESS: 'Xóa thành công!',
  NOT_FOUND: 'Không tìm thấy dữ liệu!',

  // Upload
  UPLOAD_SUCCESS: 'Upload thành công!',
  UPLOAD_FAILED: 'Upload thất bại!',
  DELETE_FILE_SUCCESS: 'Xóa file thành công!',
  INVALID_FILE_TYPE: 'Loại file không được hỗ trợ!',
  FILE_TOO_LARGE: 'File quá lớn!',

  // Game & Learning
  RESULT_SAVED: 'Kết quả đã được lưu!',
  MISSION_CLAIMED: 'Nhận thưởng nhiệm vụ thành công!',
  MISSION_NOT_COMPLETED: 'Nhiệm vụ chưa hoàn thành!',
  MISSION_ALREADY_CLAIMED: 'Nhiệm vụ đã được nhận thưởng!',
  BADGE_UNLOCKED: 'Mở khóa huy hiệu mới!',
  LEVEL_UP: 'Lên cấp!',

  // General
  SERVER_ERROR: 'Lỗi server!',
  VALIDATION_ERROR: 'Dữ liệu không hợp lệ!',
  RATE_LIMIT: 'Quá nhiều request. Vui lòng thử lại sau!',
};

// ========================================
// Socket Events
// ========================================
const SOCKET_EVENTS = {
  XP_UPDATE: 'xp:update',
  LEVEL_UPDATE: 'level:update',
  RANK_UPDATE: 'rank:update',
  BADGE_UNLOCK: 'badge:unlock',
  NOTIFICATION: 'notification:new',
  STREAK_UPDATE: 'streak:update',
  PROGRESS_SYNC: 'progress:sync',
  LESSON_COMPLETED: 'lesson:completed',
  LESSON_UNLOCKED: 'lesson:unlocked',
};

module.exports = {
  ROLES,
  AUTH_PROVIDERS,
  LESSON_TYPES,
  SKILL_TYPES,
  BADGE_TYPES,
  GAME_TYPES,
  MISSION_TYPES,
  MISSION_ACTIONS,
  NOTIFICATION_TYPES,
  DIFFICULTY,
  RANKING_PERIODS,
  XP_CONFIG,
  STARS_CONFIG,
  UPLOAD_CONFIG,
  MESSAGES,
  SOCKET_EVENTS,
};
