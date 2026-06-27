-- ========================================
-- KHÓA LUẬN TỐT NGHIỆP - KHMERKID
-- Lược đồ cơ sở dữ liệu MySQL
-- Chuyển đổi từ MongoDB Mongoose Models
-- Tổng cộng: 21 bảng
-- ========================================

CREATE DATABASE IF NOT EXISTS `khmerkid_db`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `khmerkid_db`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ========================================
-- 1. BẢNG USER (Tài khoản người dùng)
-- ========================================
CREATE TABLE `users` (
    `id` VARCHAR(24) NOT NULL,
    `name` VARCHAR(50) NOT NULL COMMENT 'Tên người dùng',
    `email` VARCHAR(255) NOT NULL COMMENT 'Email đăng nhập',
    `password` VARCHAR(255) DEFAULT NULL COMMENT 'Mật khẩu mã hóa bcrypt',
    `avatar` VARCHAR(500) DEFAULT '' COMMENT 'URL ảnh đại diện',
    `role` ENUM('user', 'admin') DEFAULT 'user' COMMENT 'Vai trò tài khoản',
    `authProvider` ENUM('local', 'google') DEFAULT 'local' COMMENT 'Nhà cung cấp xác thực',
    `googleId` VARCHAR(255) DEFAULT NULL COMMENT 'Google OAuth ID',
    `isEmailVerified` TINYINT(1) DEFAULT 0 COMMENT 'Trạng thái xác minh email',
    `refreshToken` VARCHAR(500) DEFAULT NULL COMMENT 'Token làm mới phiên',
    `passwordResetToken` VARCHAR(255) DEFAULT NULL,
    `passwordResetExpires` DATETIME DEFAULT NULL,
    -- Gamification
    `level` INT DEFAULT 1 COMMENT 'Cấp độ hiện tại',
    `xp` INT DEFAULT 0 COMMENT 'Điểm kinh nghiệm tích lũy',
    `stars` INT DEFAULT 0 COMMENT 'Số sao tích lũy (tiền tệ ảo)',
    `streak` INT DEFAULT 0 COMMENT 'Chuỗi ngày học liên tục',
    `longestStreak` INT DEFAULT 0 COMMENT 'Chuỗi ngày học dài nhất',
    `userRank` INT DEFAULT 0 COMMENT 'Thứ hạng trên bảng xếp hạng',
    -- Learning Progress (embedded)
    `totalLessonsCompleted` INT DEFAULT 0,
    `totalGamesPlayed` INT DEFAULT 0,
    `totalStudyTime` INT DEFAULT 0 COMMENT 'Tổng thời gian học (phút)',
    `listeningLevel` INT DEFAULT 0 COMMENT 'Kỹ năng nghe (0-100)',
    `speakingLevel` INT DEFAULT 0 COMMENT 'Kỹ năng nói (0-100)',
    `readingLevel` INT DEFAULT 0 COMMENT 'Kỹ năng đọc (0-100)',
    `writingLevel` INT DEFAULT 0 COMMENT 'Kỹ năng viết (0-100)',
    `writingPracticeCount` INT DEFAULT 0,
    `readingCorrectCount` INT DEFAULT 0,
    `speakingSuccessCount` INT DEFAULT 0,
    `listeningCompleteCount` INT DEFAULT 0,
    `readingLessonsCompleted` INT DEFAULT 0,
    -- Inventory (embedded)
    `hints` INT DEFAULT 2,
    `timePowerups` INT DEFAULT 2,
    `livesPowerups` INT DEFAULT 1,
    `doubleScorePowerups` INT DEFAULT 1,
    `purchasedItems` JSON DEFAULT NULL COMMENT 'Danh sách vật phẩm đã mua',
    -- Activity
    `lastLoginDate` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `lastActiveDate` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_email` (`email`),
    UNIQUE KEY `uk_googleId` (`googleId`),
    INDEX `idx_userRank` (`userRank`),
    INDEX `idx_xp` (`xp`),
    INDEX `idx_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Tài khoản người dùng (Học sinh / Quản trị viên)';

-- ========================================
-- 2. BẢNG LESSON (Bài học)
-- ========================================
CREATE TABLE `lessons` (
    `id` VARCHAR(24) NOT NULL,
    `title` VARCHAR(255) NOT NULL COMMENT 'Tiêu đề bài học',
    `description` TEXT DEFAULT NULL COMMENT 'Mô tả bài học',
    `type` ENUM('consonant', 'vowel', 'number', 'vocabulary', 'sentence', 'coeng', 'diacritical', 'reading', 'listening', 'spelling', 'mixed') NOT NULL COMMENT 'Loại bài học',
    `khmerText` VARCHAR(255) NOT NULL COMMENT 'Chữ Khmer',
    `romanized` VARCHAR(255) DEFAULT '' COMMENT 'Phiên âm Latin',
    `meaning` VARCHAR(500) DEFAULT '' COMMENT 'Nghĩa tiếng Việt',
    `pronunciation` VARCHAR(255) DEFAULT '' COMMENT 'Hướng dẫn phát âm',
    `examples` JSON DEFAULT NULL COMMENT 'Ví dụ minh họa',
    -- Media
    `imageUrl` VARCHAR(500) DEFAULT '',
    `imagePublicId` VARCHAR(255) DEFAULT '',
    `audioUrl` VARCHAR(500) DEFAULT '',
    `audioPublicId` VARCHAR(255) DEFAULT '',
    `audioDuration` INT DEFAULT 0,
    `videoUrl` VARCHAR(500) DEFAULT '',
    -- Settings
    `difficulty` ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    `sortOrder` INT DEFAULT 0 COMMENT 'Thứ tự hiển thị',
    `category` VARCHAR(100) DEFAULT '',
    `isActive` TINYINT(1) DEFAULT 1,
    -- Extended content
    `strokeOrder` JSON DEFAULT NULL COMMENT 'Thứ tự nét viết',
    `readingLines` JSON DEFAULT NULL COMMENT 'Các dòng luyện đọc',
    `questions` JSON DEFAULT NULL COMMENT 'Câu hỏi luyện nghe',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_type_sortOrder` (`type`, `sortOrder`),
    INDEX `idx_difficulty` (`difficulty`),
    INDEX `idx_isActive` (`isActive`),
    INDEX `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Bài học trong 11 chủ đề học tập';

-- ========================================
-- 3. BẢNG PROGRESS (Tiến độ học tập tổng quát)
-- ========================================
CREATE TABLE `progresses` (
    `id` VARCHAR(24) NOT NULL,
    `userId` VARCHAR(24) NOT NULL COMMENT 'FK → users.id',
    `completedLessons` JSON DEFAULT NULL COMMENT 'Danh sách bài học đã hoàn thành',
    `unlockedLessons` JSON DEFAULT NULL COMMENT 'Danh sách bài học đã mở khóa',
    `gameResults` JSON DEFAULT NULL COMMENT 'Kết quả các phiên chơi game',
    `achievements` JSON DEFAULT NULL COMMENT 'Danh sách thành tựu đạt được',
    `lastSyncAt` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm đồng bộ cuối',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_userId` (`userId`),
    CONSTRAINT `fk_progress_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Tiến độ học tập tổng quát (Source of Truth cho đồng bộ)';

-- ========================================
-- 4. BẢNG BADGE (Huy hiệu)
-- ========================================
CREATE TABLE `badges` (
    `id` VARCHAR(24) NOT NULL,
    `name` VARCHAR(255) NOT NULL COMMENT 'Tên huy hiệu',
    `description` TEXT DEFAULT NULL COMMENT 'Mô tả huy hiệu',
    `iconUrl` VARCHAR(500) DEFAULT '' COMMENT 'URL hình ảnh huy hiệu',
    `conditionType` VARCHAR(100) DEFAULT '' COMMENT 'Loại điều kiện đạt huy hiệu',
    `targetValue` INT DEFAULT 0 COMMENT 'Giá trị mục tiêu để đạt',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Danh sách huy hiệu học tập';

-- ========================================
-- 5. BẢNG ACHIEVEMENT (Thành tựu)
-- ========================================
CREATE TABLE `achievements` (
    `id` VARCHAR(24) NOT NULL,
    `title` VARCHAR(255) NOT NULL COMMENT 'Tên thành tựu',
    `description` TEXT DEFAULT NULL COMMENT 'Mô tả thành tựu',
    `xpReward` INT DEFAULT 0 COMMENT 'XP thưởng khi đạt',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Danh sách thành tựu hệ thống';

-- ========================================
-- 6. BẢNG LIÊN KẾT USER - BADGE (N:N)
-- ========================================
CREATE TABLE `user_badges` (
    `userId` VARCHAR(24) NOT NULL,
    `badgeId` VARCHAR(24) NOT NULL,
    `earnedAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`userId`, `badgeId`),
    CONSTRAINT `fk_ub_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ub_badge` FOREIGN KEY (`badgeId`) REFERENCES `badges`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Bảng liên kết N:N giữa User và Badge';

-- ========================================
-- 7. BẢNG LIÊN KẾT USER - ACHIEVEMENT (N:N)
-- ========================================
CREATE TABLE `user_achievements` (
    `userId` VARCHAR(24) NOT NULL,
    `achievementId` VARCHAR(24) NOT NULL,
    `unlockedAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`userId`, `achievementId`),
    CONSTRAINT `fk_ua_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ua_achievement` FOREIGN KEY (`achievementId`) REFERENCES `achievements`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Bảng liên kết N:N giữa User và Achievement';

-- ========================================
-- 8. BẢNG MISSION (Nhiệm vụ hệ thống)
-- ========================================
CREATE TABLE `missions` (
    `id` VARCHAR(24) NOT NULL,
    `title` VARCHAR(255) NOT NULL COMMENT 'Tên nhiệm vụ',
    `description` TEXT DEFAULT NULL,
    `type` VARCHAR(100) NOT NULL COMMENT 'Loại nhiệm vụ',
    `targetValue` INT DEFAULT 0 COMMENT 'Chỉ tiêu hoàn thành',
    `rewardXP` INT DEFAULT 0 COMMENT 'XP thưởng',
    `rewardStars` INT DEFAULT 0 COMMENT 'Sao thưởng',
    `isActive` TINYINT(1) DEFAULT 1,
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Danh mục nhiệm vụ hàng ngày';

-- ========================================
-- 9. BẢNG MISSION_PROGRESS (Tiến độ nhiệm vụ)
-- ========================================
CREATE TABLE `mission_progresses` (
    `id` VARCHAR(24) NOT NULL,
    `userId` VARCHAR(24) NOT NULL COMMENT 'FK → users.id',
    `missionId` VARCHAR(24) NOT NULL COMMENT 'FK → missions.id',
    `progress` INT DEFAULT 0 COMMENT 'Tiến độ hiện tại',
    `isCompleted` TINYINT(1) DEFAULT 0,
    `isClaimed` TINYINT(1) DEFAULT 0 COMMENT 'Đã nhận thưởng chưa',
    `claimedAt` DATETIME DEFAULT NULL,
    `expiresAt` DATETIME NOT NULL COMMENT 'Thời điểm hết hạn (TTL)',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user_mission_expires` (`userId`, `missionId`, `expiresAt`),
    INDEX `idx_expiresAt` (`expiresAt`),
    CONSTRAINT `fk_mp_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mp_mission` FOREIGN KEY (`missionId`) REFERENCES `missions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Trạng thái thực hiện nhiệm vụ hàng ngày của học sinh';

-- ========================================
-- 10. BẢNG WRITING_PROGRESS (Tiến độ luyện viết)
-- ========================================
CREATE TABLE `writing_progresses` (
    `id` VARCHAR(24) NOT NULL,
    `userId` VARCHAR(24) NOT NULL COMMENT 'FK → users.id',
    `khmerChar` VARCHAR(10) NOT NULL COMMENT 'Chữ cái Khmer (ví dụ: ក)',
    `bestScore` INT DEFAULT 0 COMMENT 'Điểm cao nhất (0-100)',
    `stars` INT DEFAULT 0 COMMENT 'Số sao đạt được (0-3)',
    `attempts` INT DEFAULT 0 COMMENT 'Tổng số lần luyện viết',
    `isCompleted` TINYINT(1) DEFAULT 0 COMMENT 'Đã thành thạo (bestScore >= 70)',
    `history` JSON DEFAULT NULL COMMENT 'Lịch sử các lần phân tích nét vẽ',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_khmerChar` (`userId`, `khmerChar`),
    INDEX `idx_user_completed` (`userId`, `isCompleted`),
    CONSTRAINT `fk_wp_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Tiến độ và điểm số luyện viết chữ cái Khmer';

-- ========================================
-- 11. BẢNG STANDARD_CHARACTER (Mẫu chữ chuẩn AI)
-- ========================================
CREATE TABLE `standard_characters` (
    `id` VARCHAR(24) NOT NULL,
    `khmerChar` VARCHAR(10) NOT NULL COMMENT 'Chữ cái Khmer chuẩn (ví dụ: ក)',
    `romanized` VARCHAR(50) DEFAULT '' COMMENT 'Phiên âm Latin',
    `type` ENUM('consonant', 'vowel', 'number', 'diacritical', 'combined') DEFAULT 'consonant',
    `standardStrokes` JSON NOT NULL COMMENT 'Tọa độ nét vẽ chuẩn Golden Path',
    `totalStrokes` INT NOT NULL COMMENT 'Tổng số nét viết',
    `difficulty` ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    `hint` VARCHAR(500) DEFAULT '' COMMENT 'Gợi ý hướng dẫn viết',
    `isActive` TINYINT(1) DEFAULT 1,
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_khmerChar` (`khmerChar`),
    INDEX `idx_type_difficulty` (`type`, `difficulty`),
    INDEX `idx_isActive` (`isActive`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Tọa độ các nét chữ Khmer chuẩn phục vụ so khớp DTW';

-- ========================================
-- 12. BẢNG GAME_PLAY_SESSION (Phiên chơi mini-game)
-- ========================================
CREATE TABLE `game_play_sessions` (
    `id` VARCHAR(24) NOT NULL,
    `userId` VARCHAR(24) NOT NULL COMMENT 'FK → users.id',
    `lessonId` VARCHAR(50) NOT NULL COMMENT 'Mã bài học liên quan',
    `characterId` VARCHAR(50) NOT NULL COMMENT 'Mã chữ cái liên quan',
    `totalQuestions` INT DEFAULT 20 COMMENT 'Tổng số câu hỏi (cố định 20)',
    `correctAnswers` INT NOT NULL COMMENT 'Số câu trả lời đúng',
    `wrongAnswers` INT NOT NULL COMMENT 'Số câu trả lời sai',
    `stars` INT DEFAULT 0,
    `bonusStars` INT DEFAULT 0,
    `totalStars` INT DEFAULT 0 COMMENT 'Tổng sao đạt được',
    `xp` INT DEFAULT 0,
    `bonusXP` INT DEFAULT 0,
    `totalXP` INT DEFAULT 0 COMMENT 'Tổng XP đạt được',
    `perfectReward` TINYINT(1) DEFAULT 0 COMMENT 'Trả lời đúng 100%',
    `completedAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_userId` (`userId`),
    CONSTRAINT `fk_gps_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Phiên chơi mini-game của học sinh';

-- ========================================
-- 13. BẢNG GAME_PROGRESS (Tiến trình trò chơi)
-- ========================================
CREATE TABLE `game_progresses` (
    `id` VARCHAR(24) NOT NULL,
    `userId` VARCHAR(24) NOT NULL COMMENT 'FK → users.id',
    `lessonId` VARCHAR(50) NOT NULL,
    `characterId` VARCHAR(50) NOT NULL,
    -- Game 1: Learn Character
    `game1Completed` TINYINT(1) DEFAULT 0,
    `game1Score` INT DEFAULT 0,
    `game1Stars` INT DEFAULT 0,
    `game1Duration` INT DEFAULT 0 COMMENT 'Thời gian hoàn thành (giây)',
    `game1CompletedAt` DATETIME DEFAULT NULL,
    -- Game 2: Multiple Choice
    `game2Completed` TINYINT(1) DEFAULT 0,
    `game2Score` INT DEFAULT 0,
    `game2Stars` INT DEFAULT 0,
    `game2Duration` INT DEFAULT 0,
    `game2WrongAnswers` INT DEFAULT 0,
    `game2CompletedAt` DATETIME DEFAULT NULL,
    -- Game 3: Stroke & Puzzle
    `game3Completed` TINYINT(1) DEFAULT 0,
    `game3Score` INT DEFAULT 0,
    `game3Stars` INT DEFAULT 0,
    `game3Duration` INT DEFAULT 0,
    `game3Attempts` INT DEFAULT 0,
    `game3CompletedAt` DATETIME DEFAULT NULL,
    -- Game 4: Pronunciation
    `game4Completed` TINYINT(1) DEFAULT 0,
    `game4Score` INT DEFAULT 0,
    `game4Stars` INT DEFAULT 0,
    `game4Confidence` INT DEFAULT 0,
    `game4Similarity` INT DEFAULT 0,
    `game4RecognizedText` VARCHAR(255) DEFAULT '',
    `game4CompletedAt` DATETIME DEFAULT NULL,
    -- Totals
    `totalScore` INT DEFAULT 0,
    `totalStars` INT DEFAULT 0,
    `xp` INT DEFAULT 0,
    `unlocked` TINYINT(1) DEFAULT 0,
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_lesson_char` (`userId`, `lessonId`, `characterId`),
    CONSTRAINT `fk_gp_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Tiến trình hoàn thành 4 trò chơi mini-game';

-- ========================================
-- 14. BẢNG GAME_QUESTION (Câu hỏi trong game)
-- ========================================
CREATE TABLE `game_questions` (
    `id` VARCHAR(24) NOT NULL,
    `gameKey` VARCHAR(100) NOT NULL COMMENT 'Mã loại game (letter_catch, word_search...)',
    `title` VARCHAR(255) NOT NULL COMMENT 'Tiêu đề câu hỏi',
    `prompt` TEXT NOT NULL COMMENT 'Nội dung gợi ý/câu hỏi',
    `answer` VARCHAR(255) NOT NULL COMMENT 'Đáp án chính xác',
    `choices` JSON DEFAULT NULL COMMENT 'Danh sách phương án lựa chọn',
    `additionalData` JSON DEFAULT NULL COMMENT 'Dữ liệu bổ sung tùy game',
    `isActive` TINYINT(1) DEFAULT 1,
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_gameKey` (`gameKey`),
    INDEX `idx_isActive` (`isActive`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ngân hàng câu hỏi dùng chung cho các mini-game';

-- ========================================
-- 15. BẢNG GAME_RESULT (Kết quả trò chơi)
-- ========================================
CREATE TABLE `game_results` (
    `id` VARCHAR(24) NOT NULL,
    `userId` VARCHAR(24) NOT NULL COMMENT 'FK → users.id',
    `gameType` VARCHAR(50) NOT NULL COMMENT 'Loại trò chơi',
    `score` INT NOT NULL COMMENT 'Điểm số đạt được',
    `stars` INT DEFAULT 0,
    `gameLevel` INT DEFAULT 1 COMMENT 'Cấp độ game đã chơi',
    `playTime` INT DEFAULT 0 COMMENT 'Thời gian chơi (giây)',
    `correctAnswers` INT DEFAULT 0,
    `totalQuestions` INT DEFAULT 0,
    `xpEarned` INT DEFAULT 0 COMMENT 'XP kiếm được',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user_game_time` (`userId`, `gameType`, `createdAt` DESC),
    CONSTRAINT `fk_gr_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Kết quả lưu điểm các trò chơi';

-- ========================================
-- 16. BẢNG LISTENING_RESULT (Kết quả luyện nghe)
-- ========================================
CREATE TABLE `listening_results` (
    `id` VARCHAR(24) NOT NULL,
    `userId` VARCHAR(24) NOT NULL COMMENT 'FK → users.id',
    `lessonId` VARCHAR(24) DEFAULT NULL COMMENT 'FK → lessons.id',
    `score` INT DEFAULT 0 COMMENT 'Điểm số (0-100)',
    `correctAnswers` INT DEFAULT 0,
    `totalQuestions` INT DEFAULT 0,
    `passed` TINYINT(1) DEFAULT 0 COMMENT 'Đạt yêu cầu',
    `xpEarned` INT DEFAULT 0,
    `answers` JSON DEFAULT NULL COMMENT 'Chi tiết từng câu trả lời',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user_lesson_time` (`userId`, `lessonId`, `createdAt` DESC),
    CONSTRAINT `fk_lr_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lr_lesson` FOREIGN KEY (`lessonId`) REFERENCES `lessons`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Kết quả rèn luyện kỹ năng nghe';

-- ========================================
-- 17. BẢNG READING_RESULT (Kết quả luyện đọc)
-- ========================================
CREATE TABLE `reading_results` (
    `id` VARCHAR(24) NOT NULL,
    `userId` VARCHAR(24) NOT NULL COMMENT 'FK → users.id',
    `lessonId` VARCHAR(24) DEFAULT NULL COMMENT 'FK → lessons.id',
    `score` INT DEFAULT 0 COMMENT 'Điểm số (0-100)',
    `accuracy` INT DEFAULT 0 COMMENT 'Độ chính xác (0-100)',
    `wordsRead` INT DEFAULT 0 COMMENT 'Số từ đã đọc',
    `totalWords` INT DEFAULT 0 COMMENT 'Tổng số từ',
    `timeSpent` INT DEFAULT 0 COMMENT 'Thời gian đọc (giây)',
    `passed` TINYINT(1) DEFAULT 0,
    `xpEarned` INT DEFAULT 0,
    `linesCompleted` JSON DEFAULT NULL COMMENT 'Chi tiết từng dòng đã đọc',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user_lesson_time` (`userId`, `lessonId`, `createdAt` DESC),
    CONSTRAINT `fk_rr_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rr_lesson` FOREIGN KEY (`lessonId`) REFERENCES `lessons`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Kết quả rèn luyện kỹ năng đọc';

-- ========================================
-- 18. BẢNG TEST_QUESTION (Ngân hàng câu hỏi kiểm tra)
-- ========================================
CREATE TABLE `test_questions` (
    `id` VARCHAR(24) NOT NULL,
    `question` VARCHAR(500) NOT NULL COMMENT 'Nội dung câu hỏi',
    `options` JSON NOT NULL COMMENT 'Danh sách phương án (≥ 2)',
    `answer` VARCHAR(255) NOT NULL COMMENT 'Đáp án chính xác',
    `testRange` VARCHAR(50) NOT NULL COMMENT 'Phạm vi bài test (ví dụ: 6-10, 1-40)',
    `isActive` TINYINT(1) DEFAULT 1,
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_testRange` (`testRange`),
    INDEX `idx_isActive` (`isActive`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ngân hàng câu hỏi kiểm tra trắc nghiệm';

-- ========================================
-- 19. BẢNG LIBRARY_ITEM (Tài liệu thư viện)
-- ========================================
CREATE TABLE `library_items` (
    `id` VARCHAR(24) NOT NULL,
    `title` VARCHAR(255) NOT NULL COMMENT 'Tiêu đề tài liệu',
    `type` ENUM('Sách', 'Audio', 'Video') NOT NULL COMMENT 'Loại tài liệu',
    `description` TEXT DEFAULT NULL,
    `image` VARCHAR(500) DEFAULT '' COMMENT 'URL ảnh bìa',
    `contentUrl` VARCHAR(500) DEFAULT '' COMMENT 'URL nội dung',
    `views` INT DEFAULT 0 COMMENT 'Lượt xem',
    `rating` DOUBLE DEFAULT 5.0 COMMENT 'Đánh giá (0-5)',
    `duration` VARCHAR(50) DEFAULT '' COMMENT 'Thời lượng',
    `isActive` TINYINT(1) DEFAULT 1,
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_isActive` (`isActive`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Kho tài nguyên sách truyện bổ trợ';

-- ========================================
-- 20. BẢNG NOTIFICATION (Thông báo)
-- ========================================
CREATE TABLE `notifications` (
    `id` VARCHAR(24) NOT NULL,
    `userId` VARCHAR(24) NOT NULL COMMENT 'FK → users.id',
    `title` VARCHAR(255) NOT NULL COMMENT 'Tiêu đề thông báo',
    `message` TEXT NOT NULL COMMENT 'Nội dung thông báo',
    `type` ENUM('system', 'achievement', 'reminder', 'promotion') NOT NULL COMMENT 'Loại thông báo',
    `isRead` TINYINT(1) DEFAULT 0 COMMENT 'Đã đọc chưa',
    `reminderType` ENUM('daily_first', 'daily_second', 'streak_warning', 'comeback') DEFAULT NULL,
    `data` JSON DEFAULT NULL COMMENT 'Dữ liệu bổ sung đính kèm',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user_read_time` (`userId`, `isRead`, `createdAt` DESC),
    CONSTRAINT `fk_notif_user` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Thông báo đẩy và nhắc nhở học tập';

-- ========================================
-- 21. BẢNG TTS_CACHE (Bộ đệm âm thanh TTS)
-- ========================================
CREATE TABLE `tts_caches` (
    `id` VARCHAR(24) NOT NULL,
    `sourceText` VARCHAR(255) NOT NULL COMMENT 'Văn bản cần phát âm',
    `locale` VARCHAR(10) NOT NULL DEFAULT 'km' COMMENT 'Ngôn ngữ (km = Khmer)',
    `audioBase64` LONGTEXT NOT NULL COMMENT 'Dữ liệu âm thanh mã hóa Base64',
    `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Tự động xóa sau 30 ngày',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sourceText_locale` (`sourceText`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Bộ nhớ đệm âm thanh phát âm Khmer TTS';

SET FOREIGN_KEY_CHECKS = 1;

-- ========================================
-- GHI CHÚ CHUYỂN ĐỔI MONGODB → MYSQL
-- ========================================
-- 1. ObjectId (24 hex chars) → VARCHAR(24)
-- 2. String → VARCHAR(n) hoặc TEXT
-- 3. Number (integer) → INT
-- 4. Number (float) → DOUBLE
-- 5. Boolean → TINYINT(1)
-- 6. Date → DATETIME
-- 7. Array / Object / Mixed → JSON
-- 8. String (large base64) → LONGTEXT
-- 9. MongoDB embedded arrays (badges[], achievements[]) → Bảng liên kết N:N riêng
-- 10. MongoDB compound unique index → UNIQUE KEY trên nhiều cột
-- 11. MongoDB TTL index (expiresAt) → MySQL Event Scheduler xóa dòng hết hạn
