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
    title: 'Nhà thông thái nhí 📚',
    description: 'Hoàn thành 2 bài học mới bất kỳ trong ngày.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.COMPLETE_LESSON,
    requirement: 2,
    reward: { xp: 20, stars: 2 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/complete.png',
    order: 1,
  },
  {
    title: 'Luyện viết chữ đẹp ✍️',
    description: 'Luyện vẽ/viết chính xác 5 chữ cái (qua tính năng nhận diện viết tay).',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.WRITE_LESSON,
    requirement: 5,
    reward: { xp: 30, stars: 3 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/write.png',
    order: 2,
  },
  {
    title: 'Đôi tai nhạy bén 🎧',
    description: 'Luyện nghe phát âm và chọn đúng đáp án 5 lần.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.LISTEN_LESSON,
    requirement: 5,
    reward: { xp: 25, stars: 2 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/listen.png',
    order: 3,
  },
  {
    title: 'Giọng ca oanh vàng 🗣️',
    description: 'Phát âm to, rõ ràng và đúng 3 từ vựng (qua nhận diện giọng nói).',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.SPEAK_LESSON,
    requirement: 3,
    reward: { xp: 35, stars: 3 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/speak.png',
    order: 4,
  },
  {
    title: 'Vừa học vừa chơi 🎮',
    description: 'Tham gia và hoàn thành 2 trò chơi ôn tập từ vựng.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.PLAY_GAME,
    requirement: 2,
    reward: { xp: 20, stars: 2 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/game.png',
    order: 5,
  },
  {
    title: 'Điểm số hoàn hảo 🎯',
    description: 'Đạt điểm tuyệt đối 100% trong ít nhất 1 bài học hoặc trò chơi.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.COMPLETE_LESSON,
    requirement: 1,
    reward: { xp: 40, stars: 4 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/complete.png',
    order: 6,
  },
  {
    title: 'Khởi đầu ngày mới ☀️',
    description: 'Hoàn thành 1 bài học trước 12h trưa để rèn luyện tinh thần tự giác.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.COMPLETE_LESSON,
    requirement: 1,
    reward: { xp: 15, stars: 1 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/complete.png',
    order: 7,
  },
  {
    title: 'Thợ săn sao vàng ⭐',
    description: 'Tích lũy đủ 50 Sao hoặc điểm kinh nghiệm (XP) trong ngày.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.DAILY_LOGIN,
    requirement: 1,
    reward: { xp: 20, stars: 2 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/login.png',
    order: 8,
  },
  {
    title: 'Trí nhớ siêu đỉnh 🔄',
    description: 'Ôn tập lại 3 từ vựng cũ đã học từ những ngày trước.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.READ_LESSON,
    requirement: 3,
    reward: { xp: 25, stars: 2 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/read.png',
    order: 9,
  },
  {
    title: 'Gặp gỡ bạn bè 🏆',
    description: 'Truy cập vào Bảng xếp hạng (Leaderboard) 1 lần để xem vị trí của mình.',
    type: MISSION_TYPES.DAILY,
    action: MISSION_ACTIONS.DAILY_LOGIN,
    requirement: 1,
    reward: { xp: 10, stars: 1 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/login.png',
    order: 10,
  },

  // --- WEEKLY MISSIONS ---
  {
    title: 'Chuỗi ngày vàng 🔥',
    description: 'Học liên tiếp 5 ngày trong tuần để duy trì ngọn lửa học tập.',
    type: MISSION_TYPES.WEEKLY,
    action: MISSION_ACTIONS.DAILY_LOGIN,
    requirement: 5,
    reward: { xp: 100, stars: 10 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/weekly_complete.png',
    order: 11,
  },
  {
    title: 'Đại sứ vựng 👑',
    description: 'Hoàn thành xuất sắc 15 bài học trong tuần.',
    type: MISSION_TYPES.WEEKLY,
    action: MISSION_ACTIONS.COMPLETE_LESSON,
    requirement: 15,
    reward: { xp: 150, stars: 15 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/weekly_complete.png',
    order: 12,
  },
  {
    title: 'Cao thủ trò chơi 🕹️',
    description: 'Tham gia chơi game ôn tập đủ 10 lần trong tuần.',
    type: MISSION_TYPES.WEEKLY,
    action: MISSION_ACTIONS.PLAY_GAME,
    requirement: 10,
    reward: { xp: 120, stars: 12 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/weekly_game.png',
    order: 13,
  },
  {
    title: 'Cơn mưa quà tặng 🎁',
    description: 'Đạt cột mốc tích lũy 500 Sao/XP từ tất cả các hoạt động học tập trong tuần.',
    type: MISSION_TYPES.WEEKLY,
    action: MISSION_ACTIONS.COMPLETE_LESSON,
    requirement: 10,
    reward: { xp: 200, stars: 20 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/weekly_complete.png',
    order: 14,
  },
  {
    title: 'Bàn tay khéo léo ✍️',
    description: 'Viết chính xác tổng cộng 20 chữ cái hoặc từ vựng trong tuần.',
    type: MISSION_TYPES.WEEKLY,
    action: MISSION_ACTIONS.WRITE_LESSON,
    requirement: 20,
    reward: { xp: 160, stars: 16 },
    iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/missions/weekly_write.png',
    order: 15,
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
