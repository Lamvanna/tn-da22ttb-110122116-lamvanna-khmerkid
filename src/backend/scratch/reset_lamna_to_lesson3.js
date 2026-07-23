/**
 * Reset tài khoản lamna01633661157@gmail.com về bài học đầu tiên
 * - Phụ âm: chỉ giữ lại 1 bài đầu (index 0)
 * - Nguyên âm: xóa hết
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const mongoose = require('mongoose');
const User = require('../src/models/User');
const Progress = require('../src/models/Progress');
const Lesson = require('../src/models/Lesson');

const MONGODB_URI = process.env.MONGODB_URI || process.env.MONGO_URI;
const TARGET_EMAIL = 'lamna01633661157@gmail.com';

async function resetLamNaAccount() {
  try {
    console.log('🔗 Đang kết nối MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Đã kết nối MongoDB!\n');

    // Tìm user
    const user = await User.findOne({ email: TARGET_EMAIL });
    if (!user) {
      console.error('❌ Không tìm thấy user với email:', TARGET_EMAIL);
      process.exit(1);
    }

    console.log(`📧 Tìm thấy user: ${user.name} (${user.email})`);
    console.log(`   ID: ${user._id}`);
    console.log(`   Hiện tại: ${user.stars}⭐, ${user.xp}XP\n`);

    // Lấy danh sách bài học - CHỈ 1 BÀI ĐẦU TIÊN
    const consonantLessons = await Lesson.find({ type: 'consonant' }).sort({ order: 1 }).limit(1);
    const vowelLessons = []; // Không giữ nguyên âm

    console.log('📚 Danh sách bài học giữ lại:');
    console.log('\n🅰️  Phụ âm (1 bài đầu):');
    consonantLessons.forEach((l, i) => {
      console.log(`   ${i}. ${l.khmerText} (${l.romanization}) - ID: ${l._id}`);
    });
    console.log('\n🔤 Nguyên âm: Không giữ bài nào');

    const keepLessonIds = [
      ...consonantLessons.map(l => l._id.toString()),
      ...vowelLessons.map(l => l._id.toString())
    ];

    // Tìm Progress document
    let progress = await Progress.findOne({ userId: user._id });
    
    if (!progress) {
      console.log('\n⚠️  Không tìm thấy Progress document. Tạo mới...');
      progress = await Progress.create({
        userId: user._id,
        completedLessons: [],
        unlockedLessons: [],
        gameResults: [],
        achievements: []
      });
    }

    // Lọc chỉ giữ 1 bài đầu của consonant
    const oldCompleted = progress.completedLessons.length;
    progress.completedLessons = progress.completedLessons.filter(lesson => {
      const lessonId = lesson.lessonId?.toString();
      return keepLessonIds.includes(lessonId);
    });

    // Tính toán lại stars và XP dựa trên 1 bài còn lại
    const totalStars = progress.completedLessons.reduce((sum, l) => sum + (l.stars || 3), 0);
    const totalXP = progress.completedLessons.reduce((sum, l) => {
      const stars = l.stars || 3;
      return sum + (stars * 10); // Mỗi sao = 10 XP
    }, 0);

    progress.unlockedLessons = keepLessonIds;
    progress.lastSyncAt = new Date();
    await progress.save();

    console.log(`\n📊 Kết quả:
   - Đã xóa: ${oldCompleted - progress.completedLessons.length} bài học
   - Còn lại: ${progress.completedLessons.length} bài (chỉ 1 phụ âm đầu tiên)
   - Tổng stars tính lại: ${totalStars}⭐
   - Tổng XP tính lại: ${totalXP}XP
`);

    // Cập nhật User model
    user.stars = totalStars;
    user.xp = totalXP;
    user.learningProgress.totalLessonsCompleted = progress.completedLessons.length;
    user.learningProgress.completedLessons = keepLessonIds.map(id => new mongoose.Types.ObjectId(id));
    await user.save();

    console.log('✅ Đã reset tài khoản thành công!');
    console.log(`   User mới: ${user.stars}⭐, ${user.xp}XP`);
    console.log(`   Completed: ${user.learningProgress.totalLessonsCompleted} bài\n`);

  } catch (error) {
    console.error('❌ Lỗi:', error.message);
    console.error(error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Đã ngắt kết nối MongoDB');
    process.exit(0);
  }
}

resetLamNaAccount();
