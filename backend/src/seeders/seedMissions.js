/**
 * ========================================
 * Mission Seeder
 * ========================================
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Mission = require('../models/Mission');
const { MISSION_TYPES, MISSION_ACTIONS } = require('../constants');

const missions = [
  // --- DAILY MISSIONS ---
  {
    title: 'Chào Ngày Mới! ☀️',
    description: 'Đăng nhập vào ứng dụng hôm nay để nhận thưởng.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.DAILY_LOGIN,
    requirement: 1,
    reward: { xp: 10, stars: 1 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/login.png',
    order: 1,
  },
  {
    title: 'Đôi Tai Thấu Suốt 🎧',
    description: 'Hoàn thành nghe 2 bài học Khmer.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.LISTEN_LESSON,
    requirement: 2,
    reward: { xp: 20, stars: 2 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/listen.png',
    order: 2,
  },
  {
    title: 'Phát Âm Tự Tin 🗣️',
    description: 'Luyện nói 2 bài học phát âm Khmer.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.SPEAK_LESSON,
    requirement: 2,
    reward: { xp: 30, stars: 3 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/speak.png',
    order: 3,
  },
  {
    title: 'Nét Vẽ Đẹp Đẽ ✍️',
    description: 'Luyện viết thành công 1 bài học tập viết.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.WRITE_LESSON,
    requirement: 1,
    reward: { xp: 25, stars: 2 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/write.png',
    order: 4,
  },
  {
    title: 'Đọc To Trôi Chảy 📖',
    description: 'Luyện đọc thành công 2 bài học đọc từ/câu.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.READ_LESSON,
    requirement: 2,
    reward: { xp: 20, stars: 2 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/read.png',
    order: 5,
  },
  {
    title: 'Đấu Sĩ Trò Chơi 🎮',
    description: 'Hoàn thành 3 trò chơi giáo dục.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.PLAY_GAME,
    requirement: 3,
    reward: { xp: 35, stars: 3 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/game.png',
    order: 6,
  },
  {
    title: 'Nhà Uyên Bác Nhỏ 🎓',
    description: 'Hoàn thành xuất sắc 3 bài học bất kỳ.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.COMPLETE_LESSON,
    requirement: 3,
    reward: { xp: 30, stars: 4 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/complete.png',
    order: 7,
  },

  // --- WEEKLY MISSIONS ---
  {
    title: 'Chiến Binh Chăm Chỉ Hàng Tuần 🏆',
    description: 'Hoàn thành 10 bài học trong tuần này.',
    type: MISSION_TYPES.WEEKLY,
    action: MISSION_ACTIONS.COMPLETE_LESSON,
    requirement: 10,
    reward: { xp: 150, stars: 15 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/weekly_complete.png',
    order: 8,
  },
  {
    title: 'Bậc Thầy Game Trí Tuệ 👑',
    description: 'Vượt qua 15 trò chơi trong tuần này.',
    type: MISSION_TYPES.WEEKLY,
    action: MISSION_ACTIONS.PLAY_GAME,
    requirement: 15,
    reward: { xp: 200, stars: 20 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/weekly_game.png',
    order: 9,
  },
  {
    title: 'Giọng Nói Vàng Của Tuần 📣',
    description: 'Luyện nói 10 bài học phát âm trong tuần.',
    type: MISSION_TYPES.WEEKLY,
    action: MISSION_ACTIONS.SPEAK_LESSON,
    requirement: 10,
    reward: { xp: 180, stars: 18 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/weekly_speak.png',
    order: 10,
  },
  {
    title: 'Kỹ Sư Chữ Đẹp Tuần Này ✒️',
    description: 'Luyện viết thành công 8 nét/từ Khmer trong tuần.',
    type: MISSION_TYPES.WEEKLY,
    action: MISSION_ACTIONS.WRITE_LESSON,
    requirement: 8,
    reward: { xp: 160, stars: 16 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/weekly_write.png',
    order: 11,
  },
];

const seedMissions = async () => {
  try {
    console.log('⏳ Seeding Missions into Database...');

    // Clear existing missions
    const deleteResult = await Mission.deleteMany({});
    console.log(`🧹 Cleared ${deleteResult.deletedCount} old missions.`);

    // Insert new missions
    const insertedMissions = await Mission.insertMany(missions);
    console.log(`🎉 Successfully seeded ${insertedMissions.length} new missions!`);

    return insertedMissions;
  } catch (error) {
    console.error('❌ Error seeding missions:', error.message);
    throw error;
  }
};

// If run directly
if (require.main === module) {
  mongoose.connect(process.env.MONGO_URI)
    .then(() => {
      console.log('🔌 Connected to MongoDB for seeding missions.');
      return seedMissions();
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

module.exports = seedMissions;
