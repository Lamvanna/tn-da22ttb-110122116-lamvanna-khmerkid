/**
 * ========================================
 * Badge Seeder
 * ========================================
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Badge = require('../models/Badge');
const { BADGE_TYPES } = require('../constants');

const badges = [
  // --- LEVEL BADGES ---
  {
    name: 'Mầm Non Nhỏ',
    description: 'Đạt cấp độ 5',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'level_reach', value: 5, description: 'Đạt cấp độ 5' },
    xpReward: 50,
    starsReward: 5,
    order: 1,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/level_5.png',
  },
  {
    name: 'Học Sinh Chăm Chỉ',
    description: 'Đạt cấp độ 10',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'level_reach', value: 10, description: 'Đạt cấp độ 10' },
    xpReward: 100,
    starsReward: 10,
    order: 2,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/level_10.png',
  },
  {
    name: 'Khám Phá Viên Khmer',
    description: 'Đạt cấp độ 20',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'level_reach', value: 20, description: 'Đạt cấp độ 20' },
    xpReward: 200,
    starsReward: 20,
    order: 3,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/level_20.png',
  },
  {
    name: 'Nhà Thông Thái Trẻ',
    description: 'Đạt cấp độ 30',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'level_reach', value: 30, description: 'Đạt cấp độ 30' },
    xpReward: 500,
    starsReward: 50,
    order: 4,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/level_30.png',
  },

  // --- STREAK BADGES ---
  {
    name: 'Khởi Đầu Tốt Đẹp',
    description: 'Duy trì chuỗi học tập 3 ngày',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 3, description: 'Chuỗi học tập 3 ngày liên tiếp' },
    xpReward: 30,
    starsReward: 3,
    order: 5,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/streak_3.png',
  },
  {
    name: 'Một Tuần Bền Bỉ',
    description: 'Duy trì chuỗi học tập 7 ngày',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 7, description: 'Chuỗi học tập 7 ngày liên tiếp' },
    xpReward: 80,
    starsReward: 8,
    order: 6,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/streak_7.png',
  },
  {
    name: 'Chiến Binh Kỷ Luật',
    description: 'Duy trì chuỗi học tập 15 ngày',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 15, description: 'Chuỗi học tập 15 ngày liên tiếp' },
    xpReward: 200,
    starsReward: 20,
    order: 7,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/streak_15.png',
  },
  {
    name: 'Thói Quen Vàng',
    description: 'Duy trì chuỗi học tập 30 ngày',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 30, description: 'Chuỗi học tập 30 ngày liên tiếp' },
    xpReward: 500,
    starsReward: 50,
    order: 8,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/streak_30.png',
  },

  // --- LEARNING/LESSONS BADGES ---
  {
    name: 'Bước Đi Đầu Tiên',
    description: 'Hoàn thành 5 bài học đầu tiên',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'lessons_complete', value: 5, description: 'Hoàn thành 5 bài học' },
    xpReward: 40,
    starsReward: 4,
    order: 9,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/lessons_5.png',
  },
  {
    name: 'Người Chăm Chỉ Học',
    description: 'Hoàn thành 15 bài học',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'lessons_complete', value: 15, description: 'Hoàn thành 15 bài học' },
    xpReward: 100,
    starsReward: 10,
    order: 10,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/lessons_15.png',
  },
  {
    name: 'Vượt Qua Thử Thách',
    description: 'Hoàn thành 30 bài học',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'lessons_complete', value: 30, description: 'Hoàn thành 30 bài học' },
    xpReward: 250,
    starsReward: 25,
    order: 11,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/lessons_30.png',
  },
  {
    name: 'Thạc Sĩ Bài Học',
    description: 'Hoàn thành 50 bài học',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'lessons_complete', value: 50, description: 'Hoàn thành 50 bài học' },
    xpReward: 600,
    starsReward: 60,
    order: 12,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/lessons_50.png',
  },

  // --- GAME BADGES ---
  {
    name: 'Người Chơi Tập Sự',
    description: 'Chơi hoàn thành 5 trò chơi',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'games_played', value: 5, description: 'Hoàn thành 5 trò chơi' },
    xpReward: 30,
    starsReward: 3,
    order: 13,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/games_5.png',
  },
  {
    name: 'Kỷ Lục Gia Trò Chơi',
    description: 'Chơi hoàn thành 20 trò chơi',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'games_played', value: 20, description: 'Hoàn thành 20 trò chơi' },
    xpReward: 120,
    starsReward: 12,
    order: 14,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/games_20.png',
  },
  {
    name: 'Vua Trò Chơi Trí Tuệ',
    description: 'Chơi hoàn thành 50 trò chơi',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'games_played', value: 50, description: 'Hoàn thành 50 trò chơi' },
    xpReward: 400,
    starsReward: 40,
    order: 15,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/games_50.png',
  },

  // --- STAR BADGES ---
  {
    name: 'Ví Đầy Sao Lấp Lánh',
    description: 'Tích lũy tổng cộng 50 ngôi sao',
    type: BADGE_TYPES.RANKING,
    requirement: { type: 'stars_total', value: 50, description: 'Sở hữu 50 ngôi sao' },
    xpReward: 50,
    starsReward: 5,
    order: 16,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/stars_50.png',
  },
  {
    name: 'Bầu Trời Đầy Sao',
    description: 'Tích lũy tổng cộng 150 ngôi sao',
    type: BADGE_TYPES.RANKING,
    requirement: { type: 'stars_total', value: 150, description: 'Sở hữu 150 ngôi sao' },
    xpReward: 150,
    starsReward: 15,
    order: 17,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/stars_150.png',
  },
  {
    name: 'Triệu Phú Ngôi Sao',
    description: 'Tích lũy tổng cộng 300 ngôi sao',
    type: BADGE_TYPES.RANKING,
    requirement: { type: 'stars_total', value: 300, description: 'Sở hữu 300 ngôi sao' },
    xpReward: 400,
    starsReward: 40,
    order: 18,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/stars_300.png',
  },

  // --- SKILL BADGES (PRONUNCIATION / SPEAKING / LISTENING / WRITING / READING) ---
  {
    name: 'Giọng Ca Oanh Vàng',
    description: 'Đạt kỹ năng nói cấp độ 2',
    type: BADGE_TYPES.PRONUNCIATION,
    requirement: { type: 'speaking_level', value: 2, description: 'Cấp độ Nói đạt từ 2 trở lên' },
    xpReward: 80,
    starsReward: 10,
    order: 19,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/speaking_2.png',
  },
  {
    name: 'Đôi Tai Nhạy Bén',
    description: 'Đạt kỹ năng nghe cấp độ 2',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'listening_level', value: 2, description: 'Cấp độ Nghe đạt từ 2 trở lên' },
    xpReward: 80,
    starsReward: 10,
    order: 20,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/listening_2.png',
  },
  {
    name: 'Nghệ Sĩ Nét Chữ',
    description: 'Đạt kỹ năng viết cấp độ 2',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'writing_level', value: 2, description: 'Cấp độ Viết đạt từ 2 trở lên' },
    xpReward: 80,
    starsReward: 10,
    order: 21,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/writing_2.png',
  },
  {
    name: 'Mộc thư Bản đồ',
    description: 'Đạt kỹ năng đọc cấp độ 2',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'reading_level', value: 2, description: 'Cấp độ Đọc đạt từ 2 trở lên' },
    xpReward: 80,
    starsReward: 10,
    order: 22,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/reading_2.png',
  },
  {
    name: 'Phát Âm Chuẩn Mực',
    description: 'Đạt kỹ năng nói cấp độ 5',
    type: BADGE_TYPES.PRONUNCIATION,
    requirement: { type: 'speaking_level', value: 5, description: 'Cấp độ Nói đạt từ 5 trở lên' },
    xpReward: 250,
    starsReward: 30,
    order: 23,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/speaking_5.png',
  },
  {
    name: 'Bậc Thầy Chữ Đẹp',
    description: 'Đạt kỹ năng viết cấp độ 5',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'writing_level', value: 5, description: 'Cấp độ Viết đạt từ 5 trở lên' },
    xpReward: 250,
    starsReward: 30,
    order: 24,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/writing_5.png',
  },
];

const seedBadges = async () => {
  try {
    console.log('⏳ Seeding Badges into Database...');
    
    // Clear existing badges
    const deleteResult = await Badge.deleteMany({});
    console.log(`🧹 Cleared ${deleteResult.deletedCount} old badges.`);

    // Insert new badges
    const insertedBadges = await Badge.insertMany(badges);
    console.log(`🎉 Successfully seeded ${insertedBadges.length} new badges!`);
    
    return insertedBadges;
  } catch (error) {
    console.error('❌ Error seeding badges:', error.message);
    throw error;
  }
};

// If run directly
if (require.main === module) {
  mongoose.connect(process.env.MONGO_URI)
    .then(() => {
      console.log('🔌 Connected to MongoDB for seeding badges.');
      return seedBadges();
    })
    .then(() => {
      console.log('🔌 Closing connection...');
      return mongoose.connection.close();
    })
    .then(() => {
      console.log('👋 Seeder finished successfully.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Fatal error in seeder:', err);
      process.exit(1);
    });
}

module.exports = seedBadges;
