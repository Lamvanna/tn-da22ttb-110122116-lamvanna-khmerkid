require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../src/models/User');
const Progress = require('../src/models/Progress');

async function run() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('🔌 Connected to MongoDB.');

    // Find the most recently updated progress documents
    const progressList = await Progress.find({})
      .sort({ updatedAt: -1 })
      .limit(5);

    console.log('📅 Most recently updated progress documents:');
    for (const prog of progressList) {
      const user = await User.findById(prog.userId).select('name email');
      console.log(`- User: ${user ? user.name : 'Unknown'} (${user ? user.email : 'N/A'})`);
      console.log(`  Updated At: ${prog.updatedAt}`);
      console.log(`  Completed lessons count: ${prog.completedLessons.length}`);
      
      const spelling = prog.completedLessons.filter(l => l.lessonType === 'spelling');
      console.log(`  Spelling lessons: ${spelling.length}`);
      spelling.forEach(l => {
        console.log(`    * ${l.lessonId} (order: ${l.lessonOrder}, stars: ${l.stars}) completed at ${l.completedAt}`);
      });

      const consonant = prog.completedLessons.filter(l => l.lessonType === 'consonant');
      console.log(`  Consonant lessons: ${consonant.length}`);
      consonant.forEach(l => {
        console.log(`    * ${l.lessonId} (order: ${l.lessonOrder}, stars: ${l.stars}) completed at ${l.completedAt}`);
      });
    }

    await mongoose.connection.close();
    console.log('🔌 Connection closed.');
  } catch (err) {
    console.error('❌ Error:', err);
    process.exit(1);
  }
}

run();
