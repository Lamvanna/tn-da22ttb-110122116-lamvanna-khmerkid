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
  // 1. Bước đầu tiên — 👣 Dấu chân vàng trên đường sáng
  {
    name: 'Bước đầu tiên',
    description: 'Hoàn thành bài học đầu tiên của bé!',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'lessons_complete', value: 1, description: 'Hoàn thành bài học đầu tiên' },
    xpReward: 30,
    starsReward: 3,
    order: 1,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474894/badges/badge_1.png',
  },
  // 2. Nhà ngôn ngữ nhí — 📚 Cuốn sách thần kỳ mở ra chữ Khmer phát sáng
  {
    name: 'Nhà ngôn ngữ nhí',
    description: 'Học tập tích lũy đạt 50 điểm XP!',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'xp_total', value: 50, description: 'Tích lũy được 50 điểm XP' },
    xpReward: 30,
    starsReward: 3,
    order: 2,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474899/badges/badge_2.png',
  },
  // 3. Bậc thầy phụ âm — 🏅 Huy chương vàng khắc chữ Khmer “ក” với vòng nguyệt quế
  {
    name: 'Bậc thầy phụ âm',
    description: 'Đạt trình độ viết phụ âm cấp độ 1.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'writing_level', value: 1, description: 'Viết phụ âm đạt cấp độ 1' },
    xpReward: 40,
    starsReward: 4,
    order: 3,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474904/badges/badge_3.png',
  },
  // 4. Khám phá nguyên âm — 🌈 Các nguyên âm Khmer bay quanh cầu vồng ma thuật
  {
    name: 'Khám phá nguyên âm',
    description: 'Đạt trình độ đọc nguyên âm cấp độ 1.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'reading_level', value: 1, description: 'Đọc nguyên âm đạt cấp độ 1' },
    xpReward: 40,
    starsReward: 4,
    order: 4,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474910/badges/badge_4.png',
  },
  // 5. Vua nguyên âm — 👑 Vương miện pha lê + chữ Khmer phát sáng ở giữa
  {
    name: 'Vua nguyên âm',
    description: 'Xuất sắc đạt trình độ đọc nguyên âm cấp độ 2.',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'reading_level', value: 2, description: 'Đọc nguyên âm đạt cấp độ 2' },
    xpReward: 50,
    starsReward: 5,
    order: 5,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474915/badges/badge_5.png',
  },
  // 6. Chính tả giỏi — ✨ Bút lông thần đang viết chữ vàng trên giấy phép thuật
  {
    name: 'Chính tả giỏi',
    description: 'Đạt trình độ viết phụ âm cấp độ 2.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'writing_level', value: 2, description: 'Viết phụ âm đạt cấp độ 2' },
    xpReward: 50,
    starsReward: 5,
    order: 6,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474922/badges/badge_6.png',
  },
  // 7. Phát âm chuẩn — 🎤 Micro ánh kim phát sóng âm cầu vồng
  {
    name: 'Phát âm chuẩn',
    description: 'Đạt trình độ nói phát âm cấp độ 1.',
    type: BADGE_TYPES.PRONUNCIATION,
    requirement: { type: 'speaking_level', value: 1, description: 'Cấp độ Nói đạt từ 1 trở lên' },
    xpReward: 50,
    starsReward: 5,
    order: 7,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474930/badges/badge_7.png',
  },
  // 8. Tai thính — 🎧 Tai nghe phát nhạc cùng nốt nhạc lấp lánh
  {
    name: 'Tai thính',
    description: 'Đạt trình độ nghe tiếng Khmer cấp độ 1.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'listening_level', value: 1, description: 'Cấp độ Nghe đạt từ 1 trở lên' },
    xpReward: 40,
    starsReward: 4,
    order: 8,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474936/badges/badge_8.png',
  },
  // 9. Viết chữ đẹp — ✍️ Bàn tay chibi viết chữ Khmer bằng mực vàng
  {
    name: 'Viết chữ đẹp',
    description: 'Đạt trình độ viết Khmer cấp độ 3.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'writing_level', value: 3, description: 'Viết chữ đạt cấp độ 3' },
    xpReward: 100,
    starsReward: 10,
    order: 9,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474942/badges/badge_9.png',
  },
  // 10. Ngôi sao đầu tiên — ⭐ Ngôi sao vàng lớn có đôi mắt cute
  {
    name: 'Ngôi sao đầu tiên',
    description: 'Tích lũy được 15 ngôi sao danh giá đầu tiên.',
    type: BADGE_TYPES.RANKING,
    requirement: { type: 'stars_total', value: 15, description: 'Sở hữu 15 ngôi sao' },
    xpReward: 50,
    starsReward: 5,
    order: 10,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474947/badges/badge_10.png',
  },
  // 11. Sao sáng — 🌟 Chòm sao 3D xoay quanh viên ngọc
  {
    name: 'Sao sáng',
    description: 'Tích lũy được tổng cộng 50 ngôi sao lấp lánh.',
    type: BADGE_TYPES.RANKING,
    requirement: { type: 'stars_total', value: 50, description: 'Sở hữu 50 ngôi sao' },
    xpReward: 80,
    starsReward: 8,
    order: 11,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474894/badges/badge_1.png',
  },
  // 12. Siêu sao — 💫 Ngôi sao thiên thần có cánh và trail ánh sáng
  {
    name: 'Siêu sao',
    description: 'Sở hữu 150 ngôi sao rực rỡ lấp lánh bầu trời.',
    type: BADGE_TYPES.RANKING,
    requirement: { type: 'stars_total', value: 150, description: 'Sở hữu 150 ngôi sao' },
    xpReward: 150,
    starsReward: 15,
    order: 12,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474899/badges/badge_2.png',
  },
  // 13. Chăm chỉ — 🔥 Ngọn lửa streak hoạt hình với lịch check-in
  {
    name: 'Chăm chỉ',
    description: 'Đạt chuỗi học tập liên tục 2 ngày.',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 2, description: 'Chuỗi học tập 2 ngày' },
    xpReward: 30,
    starsReward: 3,
    order: 13,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474904/badges/badge_3.png',
  },
  // 14. Kiên trì — 📅 Cuốn lịch vàng đầy dấu tick và vòng hào quang
  {
    name: 'Kiên trì',
    description: 'Duy trì chuỗi học tập bền bỉ liên tục 7 ngày.',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 7, description: 'Chuỗi học tập 7 ngày liên tiếp' },
    xpReward: 80,
    starsReward: 8,
    order: 14,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474910/badges/badge_4.png',
  },
  // 15. Game thủ nhí — 🎮 Tay cầm pastel neon + confetti
  {
    name: 'Game thủ nhí',
    description: 'Chơi hoàn thành 5 trò chơi học tập bổ ích.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'games_played', value: 5, description: 'Hoàn thành 5 trò chơi' },
    xpReward: 30,
    starsReward: 3,
    order: 15,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474915/badges/badge_5.png',
  },
  // 16. Vô địch mini game — 🏆 Cúp vàng chibi có gem đỏ
  {
    name: 'Vô địch mini game',
    description: 'Xuất sắc hoàn thành 20 trò chơi bổ ích.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'games_played', value: 20, description: 'Hoàn thành 20 trò chơi' },
    xpReward: 120,
    starsReward: 12,
    order: 16,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474922/badges/badge_6.png',
  },
  // 17. Tốc độ ánh sáng — ⚡ Tia sét neon lao xuyên vòng tốc độ
  {
    name: 'Tốc độ ánh sáng',
    description: 'Duy trì chuỗi học tập liên tục 15 ngày.',
    type: BADGE_TYPES.STREAK,
    requirement: { type: 'streak_days', value: 15, description: 'Chuỗi học tập 15 ngày liên tiếp' },
    xpReward: 200,
    starsReward: 20,
    order: 17,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474930/badges/badge_7.png',
  },
  // 18. Hoàn hảo — 💯 Khiên huy hiệu đỏ-vàng phát sáng
  {
    name: 'Hoàn hảo',
    description: 'Hoàn thành xuất sắc 15 bài học.',
    type: BADGE_TYPES.LEARNING,
    requirement: { type: 'lessons_complete', value: 15, description: 'Hoàn thành 15 bài học' },
    xpReward: 100,
    starsReward: 10,
    order: 18,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474936/badges/badge_8.png',
  },
  // 19. Nhà vô địch — 🥇 Huy chương số 1 trên bục chiến thắng
  {
    name: 'Nhà vô địch',
    description: 'Hoàn thành xuất sắc 30 bài học.',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'lessons_complete', value: 30, description: 'Hoàn thành 30 bài học' },
    xpReward: 250,
    starsReward: 25,
    order: 19,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474942/badges/badge_9.png',
  },
  // 20. Bậc thầy Khmer — 🎓 Nhà sư Khmer chibi đội mũ tốt nghiệp cầm sách cổ
  {
    name: 'Bậc thầy Khmer',
    description: 'Đạt cấp độ 20, vươn tới danh hiệu Bậc thầy Khmer!',
    type: BADGE_TYPES.LEVEL,
    requirement: { type: 'level_reach', value: 20, description: 'Đạt cấp độ 20' },
    xpReward: 300,
    starsReward: 30,
    order: 20,
    iconUrl: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781474947/badges/badge_10.png',
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
