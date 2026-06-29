/**
 * Reset stars và XP cho user sau khi fix double-counting
 * Tính lại đúng dựa trên số bài đã hoàn thành
 */
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

async function resetUserStars() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');

  const User = require('../src/models/User');
  const Progress = require('../src/models/Progress');

  // Tìm user "Na ne123"
  const user = await User.findOne({ name: 'Na ne123' });
  if (!user) {
    console.log('User not found!');
    process.exit(1);
  }

  console.log(`\nUser: ${user.name} (${user._id})`);
  console.log(`Current Stars: ${user.stars}`);
  console.log(`Current XP: ${user.xp}`);

  // Lấy progress
  const progress = await Progress.findOne({ userId: user._id });
  const completedLessons = progress?.completedLessons?.filter(l => l.isCompleted) || [];
  console.log(`\nCompleted lessons: ${completedLessons.length}`);

  for (const lesson of completedLessons) {
    console.log(`  - ${lesson.lessonId} (${lesson.lessonType}) order=${lesson.lessonOrder}, stars=${lesson.stars}`);
  }

  // Reset stars và XP về 0 — Flutter client sẽ cộng lại đúng khi sync
  console.log('\n⚠️  Resetting stars and XP to 0...');
  user.stars = 0;
  user.xp = 0;
  await user.save();
  
  console.log(`✅ Done! Stars: ${user.stars}, XP: ${user.xp}`);
  console.log('Flutter client sẽ hiển thị đúng từ bộ nhớ thiết bị.');

  await mongoose.disconnect();
}

resetUserStars().catch(err => {
  console.error(err);
  process.exit(1);
});
