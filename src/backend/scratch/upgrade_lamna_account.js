/**
 * ═══════════════════════════════════════════════════════════════════════
 * Upgrade Lam Na Account — Mở khóa 5 bài học đầu tiên
 * ═══════════════════════════════════════════════════════════════════════
 * 
 * Script này nâng cấp tài khoản: lamna01633661157@gmail.com
 * - Mở khóa 5 bài học đầu tiên
 * - Thêm stars và XP
 * - Thêm powerups
 * 
 * Usage: node scratch/upgrade_lamna_account.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../src/models/User');
const Lesson = require('../src/models/Lesson');
const Progress = require('../src/models/Progress');
const GameProgress = require('../src/models/GameProgress');

const TARGET_EMAIL = 'lamna01633661157@gmail.com';
const LESSONS_TO_UNLOCK = 5;

async function upgradeLamNaAccount() {
  try {
    console.log('🔌 Kết nối MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Đã kết nối MongoDB\n');

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 1: Tìm tài khoản Lam Na
    // ═══════════════════════════════════════════════════════════════════════
    console.log(`🔍 Tìm tài khoản: ${TARGET_EMAIL}...`);
    const user = await User.findOne({ email: TARGET_EMAIL });
    
    if (!user) {
      console.log(`❌ Không tìm thấy tài khoản: ${TARGET_EMAIL}`);
      console.log('💡 Hãy đảm bảo tài khoản đã được tạo trong app\n');
      return;
    }

    console.log(`   ✅ Tìm thấy: ${user.name}`);
    console.log(`   📧 Email: ${user.email}`);
    console.log(`   ⭐ Stars hiện tại: ${user.stars}`);
    console.log(`   🎯 XP hiện tại: ${user.xp}`);
    console.log(`   📊 Level hiện tại: ${user.level}\n`);

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 2: Lấy 5 bài học đầu tiên
    // ═══════════════════════════════════════════════════════════════════════
    console.log(`📚 Lấy ${LESSONS_TO_UNLOCK} bài học đầu tiên...`);
    const first5Lessons = await Lesson.find({ isActive: true })
      .sort({ order: 1 })
      .limit(LESSONS_TO_UNLOCK);
    
    if (first5Lessons.length === 0) {
      console.log('   ⚠️  Không có bài học nào trong database!');
      console.log('   💡 Chạy: node scratch/seed_lessons.js để tạo dữ liệu\n');
      return;
    }

    console.log(`   ✅ Tìm thấy ${first5Lessons.length} bài học:`);
    first5Lessons.forEach((lesson, index) => {
      console.log(`      ${index + 1}. ${lesson.title} (${lesson.lessonId})`);
    });
    console.log('');

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 3: Cập nhật hoặc tạo Progress
    // ═══════════════════════════════════════════════════════════════════════
    console.log('📝 Cập nhật Progress...');
    let progress = await Progress.findOne({ userId: user._id });

    // Chuẩn bị dữ liệu lessons
    const completedLessonsData = first5Lessons.map((lesson, index) => ({
      lessonId: lesson.lessonId || lesson._id.toString(),
      lessonType: lesson.lessonType || 'consonant',
      lessonOrder: lesson.order || index + 1,
      stars: 15, // 3 sao/bài × 5 bài
      isCompleted: true,
      completedAt: new Date(),
    }));

    const unlockedLessonsData = first5Lessons.map(lesson => 
      lesson.lessonId || lesson._id.toString()
    );

    if (!progress) {
      // Tạo mới Progress
      progress = await Progress.create({
        userId: user._id,
        completedLessons: completedLessonsData,
        unlockedLessons: unlockedLessonsData,
        gameResults: [],
        achievements: [],
        lastSyncAt: new Date(),
      });
      console.log('   ✅ Đã tạo Progress mới');
    } else {
      // Cập nhật Progress hiện có
      // Merge với lessons cũ (nếu có)
      const existingUnlocked = new Set(progress.unlockedLessons || []);
      unlockedLessonsData.forEach(id => existingUnlocked.add(id));
      
      const existingCompleted = progress.completedLessons || [];
      const newCompleted = [...existingCompleted];
      
      // Thêm lessons mới vào completed (nếu chưa có)
      for (const newLesson of completedLessonsData) {
        const exists = existingCompleted.find(l => l.lessonId === newLesson.lessonId);
        if (!exists) {
          newCompleted.push(newLesson);
        }
      }

      progress.unlockedLessons = Array.from(existingUnlocked);
      progress.completedLessons = newCompleted;
      progress.lastSyncAt = new Date();
      await progress.save();
      console.log('   ✅ Đã cập nhật Progress');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 4: Tạo Game Progress cho 5 bài đầu
    // ═══════════════════════════════════════════════════════════════════════
    console.log('🎮 Tạo Game Progress...');
    let gameCount = 0;

    for (const lesson of first5Lessons) {
      const characterIds = ['001', '002', '003', '004', '005'];

      for (const charId of characterIds) {
        // Kiểm tra xem đã tồn tại chưa
        const existing = await GameProgress.findOne({
          userId: user._id,
          lessonId: lesson._id,
          characterId: charId,
        });

        if (!existing) {
          await GameProgress.create({
            userId: user._id,
            lessonId: lesson._id,
            characterId: charId,
            unlocked: true,
            
            // Game 1: Hoàn thành
            game1Completed: true,
            game1Score: 100,
            game1Stars: 3,
            game1BestTime: 15,
            
            // Game 2: Hoàn thành
            game2Completed: true,
            game2Score: 100,
            game2Stars: 3,
            game2BestTime: 20,
            
            // Game 3: Hoàn thành
            game3Completed: true,
            game3Score: 100,
            game3Stars: 3,
            game3BestTime: 25,
            
            lastPlayedAt: new Date(),
          });
          gameCount++;
        }
      }
    }

    console.log(`   ✅ Đã tạo ${gameCount} game progress records\n`);

    // ═══════════════════════════════════════════════════════════════════════
    // BƯỚC 5: Cập nhật User stats
    // ═══════════════════════════════════════════════════════════════════════
    console.log('⭐ Cập nhật User stats...');
    
    // Thêm stars và XP
    user.stars += 500;  // Bonus stars
    user.xp += 5000;    // Bonus XP
    
    // Cập nhật inventory
    user.inventory.hints += 10;
    user.inventory.timePowerups += 5;
    user.inventory.livesPowerups += 3;
    user.inventory.doubleScorePowerups += 2;

    // Cập nhật learning progress
    const lessonIds = first5Lessons.map(l => l._id);
    const existingLessonIds = new Set(
      user.learningProgress.completedLessons.map(id => id.toString())
    );
    
    lessonIds.forEach(id => {
      if (!existingLessonIds.has(id.toString())) {
        user.learningProgress.completedLessons.push(id);
      }
    });

    user.learningProgress.totalLessonsCompleted += LESSONS_TO_UNLOCK;
    user.learningProgress.writingPracticeCount += 15;
    user.learningProgress.readingCorrectCount += 15;
    user.learningProgress.listeningLevel = Math.min(100, user.learningProgress.listeningLevel + 10);
    user.learningProgress.speakingLevel = Math.min(100, user.learningProgress.speakingLevel + 10);
    user.learningProgress.readingLevel = Math.min(100, user.learningProgress.readingLevel + 10);
    user.learningProgress.writingLevel = Math.min(100, user.learningProgress.writingLevel + 10);

    await user.save();
    console.log('   ✅ Đã cập nhật User stats\n');

    // ═══════════════════════════════════════════════════════════════════════
    // HOÀN TẤT
    // ═══════════════════════════════════════════════════════════════════════
    console.log('═══════════════════════════════════════════════════════════════════════');
    console.log('🎉 NÂNG CẤP TÀI KHOẢN THÀNH CÔNG!');
    console.log('═══════════════════════════════════════════════════════════════════════\n');
    
    console.log('📋 THÔNG TIN TÀI KHOẢN:');
    console.log('─────────────────────────────────────────────────────────────────────');
    console.log(`👤 Tên:      ${user.name}`);
    console.log(`📧 Email:    ${user.email}`);
    console.log('─────────────────────────────────────────────────────────────────────\n');
    
    console.log('✅ CẬP NHẬT:');
    console.log(`   🔓 Đã mở khóa: ${LESSONS_TO_UNLOCK} bài học`);
    console.log(`   🎮 Game progress: ${gameCount} records mới`);
    console.log(`   ⭐ Stars: ${user.stars.toLocaleString()} (+500)`);
    console.log(`   🎯 XP: ${user.xp.toLocaleString()} (+5,000)`);
    console.log(`   📊 Level: ${user.level}`);
    console.log(`   💎 Hints: ${user.inventory.hints} (+10)`);
    console.log(`   ⏰ Time Powerups: ${user.inventory.timePowerups} (+5)`);
    console.log(`   ❤️  Lives Powerups: ${user.inventory.livesPowerups} (+3)`);
    console.log(`   ⚡ Double Score: ${user.inventory.doubleScorePowerups} (+2)\n`);

    console.log('📚 CÁC BÀI HỌC ĐÃ MỞ:');
    first5Lessons.forEach((lesson, index) => {
      console.log(`   ${index + 1}. ${lesson.title} ✅`);
    });
    console.log('');

    console.log('🚀 Đăng nhập lại để thấy các bài học mới!\n');

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
upgradeLamNaAccount();
