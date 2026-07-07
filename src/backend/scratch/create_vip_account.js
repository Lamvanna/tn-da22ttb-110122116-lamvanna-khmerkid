/**
 * ═══════════════════════════════════════════════════════════════════════
 * Create VIP Account — Tài khoản VIP với toàn bộ nội dung mở khóa
 * ═══════════════════════════════════════════════════════════════════════
 * 
 * Script này tạo 1 tài khoản VIP test với:
 * - Email: vip@khmerkid.com
 * - Password: vip123456
 * - Mở khóa TẤT CẢ bài học
 * - Mở khóa TẤT CẢ game
 * - Level cao, stars, XP nhiều
 * - Đầy đủ powerups
 * 
 * Usage: node scratch/create_vip_account.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../src/models/User');
const Lesson = require('../src/models/Lesson');
const Progress = require('../src/models/Progress');
const GameProgress = require('../src/models/GameProgress');

const VIP_EMAIL = 'vip@khmerkid.com';
const VIP_PASSWORD = 'vip123456';
const VIP_NAME = 'VIP User - Lâm Văn Na';

async function createVIPAccount() {
  try {
    console.log('🔌 Kết nối MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Đã kết nối MongoDB\n');

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 1: Xóa tài khoản VIP cũ nếu có
    // ═══════════════════════════════════════════════════════════════════════
    console.log('🗑️  Xóa tài khoản VIP cũ (nếu có)...');
    const existingUser = await User.findOne({ email: VIP_EMAIL });
    if (existingUser) {
      await Progress.deleteMany({ userId: existingUser._id });
      await GameProgress.deleteMany({ userId: existingUser._id });
      await User.deleteOne({ _id: existingUser._id });
      console.log('   ✅ Đã xóa tài khoản cũ\n');
    } else {
      console.log('   ℹ️  Không có tài khoản cũ\n');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 2: Tạo tài khoản VIP mới
    // ═══════════════════════════════════════════════════════════════════════
    console.log('👤 Tạo tài khoản VIP mới...');
    const vipUser = await User.create({
      name: VIP_NAME,
      email: VIP_EMAIL,
      password: VIP_PASSWORD,
      authProvider: 'local',
      role: 'user',
      avatar: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1234567890/avatars/vip_avatar.png',
      
      // Gamification - VIP level
      level: 50,
      xp: 100000,
      stars: 99999,
      streak: 100,
      longestStreak: 100,
      
      // Inventory đầy đủ
      inventory: {
        hints: 999,
        timePowerups: 999,
        livesPowerups: 999,
        doubleScorePowerups: 999,
        hintsLastReg: Date.now(),
        timePowerupsLastReg: Date.now(),
        livesPowerupsLastReg: Date.now(),
        doubleScorePowerupsLastReg: Date.now(),
      },

      // Mua tất cả items
      purchasedItems: [
        'voi_nau', 'voi_xanh', 'voi_hong', 'voi_vang', 'voi_tim',
        'ruong_kim_cuong', 'huy_hieu_sieu_sao', 'qua_cau_tuyet',
        'sach_tri_thuc', 'khinh_khi_cau', 'may_bay_giay',
        'avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5',
      ],

      // Learning progress tối đa
      learningProgress: {
        totalLessonsCompleted: 999,
        totalGamesPlayed: 999,
        totalStudyTime: 9999,
        listeningLevel: 100,
        speakingLevel: 100,
        readingLevel: 100,
        writingLevel: 100,
        writingPracticeCount: 999,
        readingCorrectCount: 999,
        speakingSuccessCount: 999,
        listeningCompleteCount: 999,
        readingLessonsCompleted: 999,
        completedLessons: [],
        weakSkills: [],
      },

      isEmailVerified: true,
      lastLoginDate: new Date(),
      lastActiveDate: new Date(),
    });

    console.log(`   ✅ Đã tạo user: ${vipUser.name}`);
    console.log(`   📧 Email: ${vipUser.email}`);
    console.log(`   🔑 Password: ${VIP_PASSWORD}`);
    console.log(`   ⭐ Stars: ${vipUser.stars}`);
    console.log(`   🎯 XP: ${vipUser.xp}`);
    console.log(`   📊 Level: ${vipUser.level}\n`);

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 3: Lấy tất cả bài học
    // ═══════════════════════════════════════════════════════════════════════
    console.log('📚 Lấy danh sách tất cả bài học...');
    const allLessons = await Lesson.find({ isActive: true });
    console.log(`   ✅ Tìm thấy ${allLessons.length} bài học\n`);

    if (allLessons.length === 0) {
      console.log('   ⚠️  Không có bài học nào trong database!');
      console.log('   💡 Chạy: node scratch/seed_lessons.js để tạo dữ liệu\n');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 4: Mở khóa tất cả bài học
    // ═══════════════════════════════════════════════════════════════════════
    console.log('🔓 Mở khóa tất cả bài học...');
    
    // Tạo completedLessons objects với đầy đủ fields
    const completedLessonsData = allLessons.map((lesson, index) => ({
      lessonId: lesson.lessonId || lesson._id.toString(),
      lessonType: lesson.lessonType || 'consonant',
      lessonOrder: lesson.order || index + 1,
      stars: 50, // Max stars
      isCompleted: true,
      completedAt: new Date(),
    }));

    // Tạo unlockedLessons (chỉ cần array của lessonId strings)
    const unlockedLessonsData = allLessons.map(lesson => 
      lesson.lessonId || lesson._id.toString()
    );

    const progress = await Progress.create({
      userId: vipUser._id,
      completedLessons: completedLessonsData,
      unlockedLessons: unlockedLessonsData,
      gameResults: [],
      achievements: [],
      lastSyncAt: new Date(),
    });

    console.log(`   ✅ Đã mở khóa ${unlockedLessonsData.length} bài học\n`);

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 5: Mở khóa tất cả game progress cho từng ký tự
    // ═══════════════════════════════════════════════════════════════════════
    console.log('🎮 Mở khóa tất cả game progress...');
    let gameCount = 0;

    for (const lesson of allLessons) {
      // Giả sử mỗi bài có nhiều characters (001, 002, 003...)
      // Tạo game progress cho từng character
      const characterIds = ['001', '002', '003', '004', '005']; // Có thể adjust

      for (const charId of characterIds) {
        await GameProgress.create({
          userId: vipUser._id,
          lessonId: lesson._id,
          characterId: charId,
          unlocked: true,
          
          // Game 1: Hoàn thành
          game1Completed: true,
          game1Score: 100,
          game1Stars: 3,
          game1BestTime: 10,
          
          // Game 2: Hoàn thành
          game2Completed: true,
          game2Score: 100,
          game2Stars: 3,
          game2BestTime: 15,
          
          // Game 3: Hoàn thành
          game3Completed: true,
          game3Score: 100,
          game3Stars: 3,
          game3BestTime: 20,
          
          lastPlayedAt: new Date(),
        });
        gameCount++;
      }
    }

    console.log(`   ✅ Đã tạo ${gameCount} game progress records\n`);

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 6: Cập nhật completedLessons trong learningProgress
    // ═══════════════════════════════════════════════════════════════════════
    vipUser.learningProgress.completedLessons = allLessons.map(l => l._id);
    await vipUser.save();

    // ═══════════════════════════════════════════════════════════════════════
    // HOÀN TẤT
    // ═══════════════════════════════════════════════════════════════════════
    console.log('═══════════════════════════════════════════════════════════════════════');
    console.log('🎉 TẠO TÀI KHOẢN VIP THÀNH CÔNG!');
    console.log('═══════════════════════════════════════════════════════════════════════\n');
    
    console.log('📋 THÔNG TIN ĐĂNG NHẬP:');
    console.log('─────────────────────────────────────────────────────────────────────');
    console.log(`📧 Email:    ${VIP_EMAIL}`);
    console.log(`🔑 Password: ${VIP_PASSWORD}`);
    console.log(`👤 Tên:      ${VIP_NAME}`);
    console.log('─────────────────────────────────────────────────────────────────────\n');
    
    console.log('✅ TÍNH NĂNG:');
    console.log(`   🔓 Mở khóa: ${unlockedLessonsData.length} bài học`);
    console.log(`   🎮 Game progress: ${gameCount} records`);
    console.log(`   ⭐ Stars: ${vipUser.stars.toLocaleString()}`);
    console.log(`   🎯 XP: ${vipUser.xp.toLocaleString()}`);
    console.log(`   📊 Level: ${vipUser.level}`);
    console.log(`   💎 Hints: ${vipUser.inventory.hints}`);
    console.log(`   ⏰ Time Powerups: ${vipUser.inventory.timePowerups}`);
    console.log(`   ❤️  Lives Powerups: ${vipUser.inventory.livesPowerups}`);
    console.log(`   ⚡ Double Score: ${vipUser.inventory.doubleScorePowerups}\n`);

    console.log('🚀 Bây giờ bạn có thể đăng nhập bằng tài khoản VIP này!\n');

  } catch (error) {
    console.error('❌ Lỗi:', error.message);
    console.error(error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Đã đóng kết nối MongoDB');
    process.exit(0);
  }
}

// Chạy script
createVIPAccount();
