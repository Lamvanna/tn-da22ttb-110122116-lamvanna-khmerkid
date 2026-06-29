/**
 * ========================================
 * Backfill Badge Counters
 * ========================================
 *
 * Tính toán lại các counter cho badge từ dữ liệu lịch sử:
 *   - writingPracticeCount: tổng attempts từ WritingProgress
 *   - readingLessonsCompleted: số bài đọc đã pass từ ReadingResult
 *   - readingCorrectCount: tổng wordsRead từ ReadingResult
 *   - listeningCompleteCount: số bài nghe đã pass từ ListeningResult
 *   - speakingSuccessCount: giữ nguyên (không có model lưu trữ)
 *
 * Usage: node backend/scratch/backfill_badge_counters.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const mongoose = require('mongoose');

const User = require('../src/models/User');
const WritingProgress = require('../src/models/WritingProgress');
const ReadingResult = require('../src/models/ReadingResult');
const ListeningResult = require('../src/models/ListeningResult');
const GameResult = require('../src/models/GameResult');
const Progress = require('../src/models/Progress');

async function backfill() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ Connected to MongoDB\n');

  const users = await User.find({}).select('_id name xp learningProgress');
  console.log(`📋 Found ${users.length} users\n`);

  for (const user of users) {
    const userId = user._id;
    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`👤 User: ${user.name || user._id}`);

    // 1. Writing: tổng số attempts từ WritingProgress
    const writingAgg = await WritingProgress.aggregate([
      { $match: { userId } },
      { $group: { _id: null, totalAttempts: { $sum: '$attempts' } } },
    ]);
    const writingPracticeCount = writingAgg.length > 0 ? writingAgg[0].totalAttempts : 0;

    // 2. Reading: số bài pass + tổng wordsRead
    const readingAgg = await ReadingResult.aggregate([
      { $match: { userId, passed: true } },
      {
        $group: {
          _id: null,
          lessonsCompleted: { $sum: 1 },
          totalWordsRead: { $sum: { $ifNull: ['$wordsRead', 0] } },
        },
      },
    ]);
    const readingLessonsCompleted = readingAgg.length > 0 ? readingAgg[0].lessonsCompleted : 0;
    const readingCorrectCount = readingAgg.length > 0 ? readingAgg[0].totalWordsRead : 0;

    // 3. Listening: số bài nghe đã pass
    const listeningAgg = await ListeningResult.aggregate([
      { $match: { userId, passed: true } },
      { $group: { _id: null, totalPassed: { $sum: 1 } } },
    ]);
    const listeningCompleteCount = listeningAgg.length > 0 ? listeningAgg[0].totalPassed : 0;

    // 4. Speaking: giữ nguyên (không có collection lưu trữ)
    const speakingSuccessCount = user.learningProgress?.speakingSuccessCount || 0;

    // 5. Games: tổng số game đã chơi từ GameResult
    const gamesAgg = await GameResult.aggregate([
      { $match: { userId } },
      { $group: { _id: null, totalGames: { $sum: 1 } } },
    ]);
    const totalGamesPlayed = gamesAgg.length > 0 ? gamesAgg[0].totalGames : 0;

    // 6. Reading lessons từ Progress collection (bài đọc hoàn thành qua progress/complete)
    const progressDoc = await Progress.findOne({ userId });
    let readingFromProgress = 0;
    if (progressDoc && progressDoc.completedLessons) {
      readingFromProgress = progressDoc.completedLessons.filter(
        l => l.isCompleted && l.lessonType === 'reading'
      ).length;
    }
    // Lấy max giữa ReadingResult và Progress
    const finalReadingLessons = Math.max(readingLessonsCompleted, readingFromProgress);

    // 7. Calculate study time: 5 mins per completed lesson + 3 mins per game played
    const lessonsCompletedCount = user.learningProgress?.completedLessons?.length || 0;
    let totalStudyTime = lessonsCompletedCount * 5 + totalGamesPlayed * 3;
    const xpBasedTime = Math.round((user.xp || 0) / 12);
    if (totalStudyTime < xpBasedTime) {
      totalStudyTime = xpBasedTime;
    }

    // Log trước/sau
    const before = user.learningProgress || {};
    console.log(`   writingPracticeCount:  ${before.writingPracticeCount || 0} → ${writingPracticeCount}`);
    console.log(`   readingLessonsCompleted: ${before.readingLessonsCompleted || 0} → ${finalReadingLessons} (Progress: ${readingFromProgress}, Result: ${readingLessonsCompleted})`);
    console.log(`   readingCorrectCount:   ${before.readingCorrectCount || 0} → ${readingCorrectCount}`);
    console.log(`   listeningCompleteCount: ${before.listeningCompleteCount || 0} → ${listeningCompleteCount}`);
    console.log(`   speakingSuccessCount:  ${speakingSuccessCount} (giữ nguyên)`);
    console.log(`   totalGamesPlayed:      ${before.totalGamesPlayed || 0} → ${totalGamesPlayed}`);
    console.log(`   totalStudyTime:        ${before.totalStudyTime || 0} → ${totalStudyTime}`);

    // Cập nhật lên User
    await User.findByIdAndUpdate(userId, {
      'learningProgress.writingPracticeCount': writingPracticeCount,
      'learningProgress.readingLessonsCompleted': finalReadingLessons,
      'learningProgress.readingCorrectCount': readingCorrectCount,
      'learningProgress.listeningCompleteCount': listeningCompleteCount,
      'learningProgress.totalGamesPlayed': totalGamesPlayed,
      'learningProgress.totalStudyTime': totalStudyTime,
    });

    console.log(`   ✅ Updated!\n`);
  }

  await mongoose.disconnect();
  console.log('🎉 Backfill completed!');
}

backfill().catch((err) => {
  console.error('❌ Error:', err);
  process.exit(1);
});
