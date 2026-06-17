require('dotenv').config();
const mongoose = require('mongoose');
const Progress = require('../src/models/Progress');
const Lesson = require('../src/models/Lesson');

async function run() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('🔌 Connected to MongoDB.');

    const progressList = await Progress.find({});
    
    // Get all valid lesson IDs from the database
    const validLessons = await Lesson.find({});
    const validIds = new Set(validLessons.map(l => l._id.toString()));

    console.log('Checking progress documents for stale lesson IDs...');
    for (const prog of progressList) {
      console.log(`\nUser progress for: ${prog.userId}`);
      const stale = [];
      for (const l of prog.completedLessons) {
        if (!validIds.has(l.lessonId)) {
          stale.push(l);
        }
      }
      console.log(`Found ${stale.length} stale lesson IDs out of ${prog.completedLessons.length} completed lessons.`);
      stale.forEach(l => {
        console.log(`- Stale ID: ${l.lessonId}, Type: ${l.lessonType}, Order: ${l.lessonOrder}`);
      });
    }

    await mongoose.connection.close();
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

run();
