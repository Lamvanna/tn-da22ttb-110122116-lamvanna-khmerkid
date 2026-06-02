const mongoose = require('mongoose');
require('dotenv').config();

const lessonSchema = new mongoose.Schema({}, { strict: false });
const Lesson = mongoose.model('Lesson', lessonSchema, 'lessons');

async function run() {
  const uri = process.env.MONGO_URI || "mongodb+srv://admin:PCO6NePc2Gmcifzt@lamv.tzc1slv.mongodb.net/khmerkid";
  console.log('Connecting to MongoDB...');
  await mongoose.connect(uri);
  console.log('Connected!');

  const count = await Lesson.countDocuments();
  console.log(`Total lessons in DB: ${count}`);

  const lessons = await Lesson.find({ type: 'vocabulary' }).limit(10).lean();
  console.log('Vocabulary lessons list:', JSON.stringify(lessons, null, 2));

  await mongoose.disconnect();
  console.log('Disconnected!');
}

run().catch(console.error);

