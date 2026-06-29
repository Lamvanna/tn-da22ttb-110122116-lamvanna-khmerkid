require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../src/models/User');
const Progress = require('../src/models/Progress');

async function run() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('🔌 Connected to MongoDB.');

    const email = 'hero01633661157@gmail.com';
    const user = await User.findOne({ email });
    if (!user) {
      console.log('User not found.');
      return;
    }
    console.log(`Found user: ${user.name}, current stars: ${user.stars}, XP: ${user.xp}`);

    const progress = await Progress.findOne({ userId: user._id });
    if (!progress) {
      console.log('Progress document not found.');
      return;
    }

    console.log(`Before: completedLessons count = ${progress.completedLessons.length}`);
    
    // Let's filter out consonant_1 and 6a2e8f2cdd49014abf238ecd (consonant 1) if we want to reset it completely
    const filtered = progress.completedLessons.filter(l => l.lessonId !== 'consonant_1' && l.lessonId !== '6a2e8f2cdd49014abf238ecd');
    progress.completedLessons = filtered;

    await progress.save();
    console.log(`After: completedLessons count = ${progress.completedLessons.length}`);

    // Clean user model list
    user.learningProgress.completedLessons = user.learningProgress.completedLessons.filter(
      id => id.toString() !== '6a2e8f2cdd49014abf238ecd'
    );
    await user.save();

    await mongoose.connection.close();
    console.log('🔌 Connection closed. Progress reset successfully.');
  } catch (err) {
    console.error('❌ Error:', err);
    process.exit(1);
  }
}

run();
