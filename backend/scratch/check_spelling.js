require('dotenv').config();
const mongoose = require('mongoose');
const Lesson = require('../src/models/Lesson');

async function run() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('🔌 Connected to MongoDB.');

    const count = await Lesson.countDocuments({ type: 'spelling' });
    console.log(`📝 Total spelling (ghép vần) lessons: ${count}`);

    const lessons = await Lesson.find({ type: 'spelling' }).select('title khmerText romanized meaning category');
    console.log('📋 Spelling lessons list:');
    lessons.forEach((l, idx) => {
      console.log(`  ${idx + 1}. [${l.category}] ${l.title} (${l.romanized}) - ${l.meaning}`);
    });

    await mongoose.connection.close();
    console.log('🔌 Connection closed.');
  } catch (err) {
    console.error('❌ Error querying database:', err);
    process.exit(1);
  }
}

run();
