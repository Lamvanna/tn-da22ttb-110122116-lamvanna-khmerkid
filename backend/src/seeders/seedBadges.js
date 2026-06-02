/**
 * ========================================
 * Badge Seeder (Exactly 20 Badges)
 * ========================================
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Badge = require('../models/Badge');
const { BADGE_TYPES } = require('../constants');

const badges = [
  // 1. Bước Đầu Tiên
  {
    name: 'Bước Đầu Tiên',
    description: 'Hoàn thành bài học đầu tiên của bé!',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'lessons_complete', value: 1, description: 'Hoàn thành bài học đầu tiên' },
    xpReward: 30,
    starsReward: 3,
    order: 1,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/lessons_5.png',
  },
  // 2. Đã Vẽ Đẹp
  {
    name: 'Đã Vẽ Đẹp',
    description: 'Hoàn thành 3 bài học tập viết Khmer.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'writing_lessons', value: 3, description: 'Hoàn thành 3 bài học tập viết' },
    xpReward: 40,
    starsReward: 4,
    order: 2,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/writing_2.png',
  },
  // 3. Đọc Chăm Chỉ
  {
    name: 'Đọc Chăm Chỉ',
    description: 'Hoàn thành bài học tập đọc đầu tiên.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'reading_lessons', value: 1, description: 'Hoàn thành bài học tập đọc đầu tiên' },
    xpReward: 30,
    starsReward: 3,
    order: 3,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/reading_2.png',
  },
  // 4. Ngôi Sao Sáng
  {
    name: 'Ngôi Sao Sáng',
    description: 'Tích lũy được 15 ngôi sao danh giá.',
    type: BADGE_TYPES.RANKING,
    requirement: { type: 'stars_total', value: 15, description: 'Tích lũy được 15 ngôi sao' },
    xpReward: 50,
    starsReward: 5,
    order: 4,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/stars_50.png',
  },
  // 5. Khám Phá Thế Giới
  {
    name: 'Khám Phá Thế Giới',
    description: 'Học được 2 từ vựng tiếng Khmer mới.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'vocab_learned', value: 2, description: 'Học được 2 từ vựng' },
    xpReward: 35,
    starsReward: 3,
    order: 5,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/level_5.png',
  },
  // 6. Vui Học Toán
  {
    name: 'Vui Học Toán',
    description: 'Tích lũy được 50 điểm XP học tập.',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'xp_earned', value: 50, description: 'Tích lũy được 50 điểm XP' },
    xpReward: 50,
    starsReward: 5,
    order: 6,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/level_10.png',
  },
  // 7. Ngoan Lễ Phép
  {
    name: 'Ngoan Lễ Phép',
    description: 'Đạt chuỗi học tập liên tục 2 ngày.',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 2, description: 'Chuỗi học tập 2 ngày' },
    xpReward: 40,
    starsReward: 4,
    order: 7,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/streak_3.png',
  },
  // 8. Mầm Non Nhỏ
  {
    name: 'Mầm Non Nhỏ',
    description: 'Đạt cấp độ 5',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'level_reach', value: 5, description: 'Đạt cấp độ 5' },
    xpReward: 50,
    starsReward: 5,
    order: 8,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/level_5.png',
  },
  // 9. Học Sinh Chăm Chỉ
  {
    name: 'Học Sinh Chăm Chỉ',
    description: 'Đạt cấp độ 10',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'level_reach', value: 10, description: 'Đạt cấp độ 10' },
    xpReward: 100,
    starsReward: 10,
    order: 9,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/level_10.png',
  },
  // 10. Khám Phá Viên Khmer
  {
    name: 'Khám Phá Viên Khmer',
    description: 'Đạt cấp độ 20',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'level_reach', value: 20, description: 'Đạt cấp độ 20' },
    xpReward: 200,
    starsReward: 20,
    order: 10,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/level_20.png',
  },
  // 11. Khởi Đầu Tốt Đẹp
  {
    name: 'Khởi Đầu Tốt Đẹp',
    description: 'Duy trì chuỗi học tập 3 ngày',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 3, description: 'Chuỗi học tập 3 ngày liên tiếp' },
    xpReward: 30,
    starsReward: 3,
    order: 11,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/streak_3.png',
  },
  // 12. Một Tuần Bền Bỉ
  {
    name: 'Một Tuần Bền Bỉ',
    description: 'Duy trì chuỗi học tập 7 ngày',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 7, description: 'Chuỗi học tập 7 ngày liên tiếp' },
    xpReward: 80,
    starsReward: 8,
    order: 12,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/streak_7.png',
  },
  // 13. Chiến Binh Kỷ Luật
  {
    name: 'Chiến Binh Kỷ Luật',
    description: 'Duy trì chuỗi học tập 15 ngày',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 15, description: 'Chuỗi học tập 15 ngày liên tiếp' },
    xpReward: 200,
    starsReward: 20,
    order: 13,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/streak_15.png',
  },
  // 14. Người Chăm Chỉ Học
  {
    name: 'Người Chăm Chỉ Học',
    description: 'Hoàn thành 15 bài học',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'lessons_complete', value: 15, description: 'Hoàn thành 15 bài học' },
    xpReward: 100,
    starsReward: 10,
    order: 14,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/lessons_15.png',
  },
  // 15. Vượt Qua Thử Thách
  {
    name: 'Vượt Qua Thử Thách',
    description: 'Hoàn thành 30 bài học',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'lessons_complete', value: 30, description: 'Hoàn thành 30 bài học' },
    xpReward: 250,
    starsReward: 25,
    order: 15,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/lessons_30.png',
  },
  // 16. Người Chơi Tập Sự
  {
    name: 'Người Chơi Tập Sự',
    description: 'Chơi hoàn thành 5 trò chơi',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'games_played', value: 5, description: 'Hoàn thành 5 trò chơi' },
    xpReward: 30,
    starsReward: 3,
    order: 16,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/games_5.png',
  },
  // 17. Kỷ Lục Gia Trò Chơi
  {
    name: 'Kỷ Lục Gia Trò Chơi',
    description: 'Chơi hoàn thành 20 trò chơi',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'games_played', value: 20, description: 'Hoàn thành 20 trò chơi' },
    xpReward: 120,
    starsReward: 12,
    order: 17,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/games_20.png',
  },
  // 18. Bầu Trời Đầy Sao
  {
    name: 'Bầu Trời Đầy Sao',
    description: 'Tích lũy tổng cộng 150 ngôi sao',
    type: BADGE_TYPES.RANKING,
    requirement: { type: 'stars_total', value: 150, description: 'Sở hữu 150 ngôi sao' },
    xpReward: 150,
    starsReward: 15,
    order: 18,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/stars_150.png',
  },
  // 19. Giọng Ca Oanh Vàng
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
  // 20. Đôi Tai Nhạy Bén
  {
    name: 'Đôi Tai Nhạy Bén',
    description: 'Đạt kỹ năng nghe cấp độ 2',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'listening_level', value: 2, description: 'Cấp độ Nghe đạt từ 2 trở lên' },
    xpReward: 80,
    starsReward: 10,
    order: 20,
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/listening_2.png',
  }
];

const seedBadges = async () => {
  try {
    console.log('⏳ Seeding exactly 20 Badges into Database...');
    
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
