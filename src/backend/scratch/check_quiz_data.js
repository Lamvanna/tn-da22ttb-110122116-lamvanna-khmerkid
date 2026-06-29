/**
 * Script to check count and details of TestQuestion and GameQuestion collections
 */
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

async function checkQuizData() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');

  const TestQuestion = require('../src/models/TestQuestion');
  const GameQuestion = require('../src/models/GameQuestion');

  try {
    const testCount = await TestQuestion.countDocuments({});
    console.log(`\nTotal TestQuestions: ${testCount}`);
    
    if (testCount > 0) {
      const ranges = await TestQuestion.aggregate([
        { $group: { _id: "$testRange", count: { $sum: 1 } } }
      ]);
      console.log('TestQuestions by range:');
      ranges.forEach(r => {
        console.log(`  Range [${r._id}]: ${r.count} questions`);
      });
    }

    const gameCount = await GameQuestion.countDocuments({});
    console.log(`\nTotal GameQuestions: ${gameCount}`);
    if (gameCount > 0) {
      const gameTypes = await GameQuestion.aggregate([
        { $group: { _id: "$gameType", count: { $sum: 1 } } }
      ]);
      console.log('GameQuestions by gameType:');
      gameTypes.forEach(g => {
        console.log(`  GameType [${g._id}]: ${g.count} questions`);
      });
    }

  } catch (e) {
    console.error(e);
  }

  await mongoose.disconnect();
}

checkQuizData().catch(err => {
  console.error(err);
  process.exit(1);
});
