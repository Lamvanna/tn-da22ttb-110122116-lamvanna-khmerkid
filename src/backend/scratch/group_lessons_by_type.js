/**
 * Script to check count of lessons grouped by type in MongoDB
 */
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

async function groupLessons() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');

  const Lesson = require('../src/models/Lesson');

  try {
    const counts = await Lesson.aggregate([
      { $group: { _id: "$type", count: { $sum: 1 } } }
    ]);
    console.log('\n--- LESSONS BY TYPE IN MONGO ---');
    counts.forEach(c => {
      console.log(`${c._id}: ${c.count} lessons`);
    });
  } catch (e) {
    console.error(e);
  }

  await mongoose.disconnect();
}

groupLessons().catch(err => {
  console.error(err);
  process.exit(1);
});
