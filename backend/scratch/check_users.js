require('dotenv').config();
const mongoose = require('mongoose');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  
  const User = require('../src/models/User');
  const Progress = require('../src/models/Progress');
  const GameResult = require('../src/models/GameResult');
  
  const users = await User.find().select('name email stars xp level').lean();
  console.log('--- ALL USERS ---');
  console.log(users);
  
  for (const u of users) {
    const progress = await Progress.findOne({ userId: u._id });
    console.log(`\n--- PROGRESS FOR ${u.name} ---`);
    if (progress) {
      console.log(`Completed lessons: ${progress.completedLessons.length}`);
      console.log(progress.completedLessons.map(l => ({
        lessonId: l.lessonId,
        type: l.lessonType,
        stars: l.stars,
        completedAt: l.completedAt
      })));
    } else {
      console.log('No progress document.');
    }

    const gameResults = await GameResult.find({ userId: u._id });
    console.log(`Game results: ${gameResults.length}`);
    if (gameResults.length > 0) {
      console.log(gameResults.map(g => ({
        gameType: g.gameType,
        score: g.score,
        stars: g.stars,
        xpEarned: g.xpEarned,
        createdAt: g.createdAt
      })));
    }
  }
  
  process.exit(0);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
