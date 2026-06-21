require('dotenv').config();
const mongoose = require('mongoose');

const { getStartOfWeek, getStartOfMonth } = require('../src/utils/helpers');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  
  const User = require('../src/models/User');
  const Progress = require('../src/models/Progress');
  const GameResult = require('../src/models/GameResult');

  const startOfMonth = getStartOfMonth();
  console.log('Start of month:', startOfMonth);

  // 1. Game results
  const gameRanking = await GameResult.aggregate([
    { $match: { createdAt: { $gte: startOfMonth } } },
    {
      $group: {
        _id: '$userId',
        gameXp: { $sum: '$xpEarned' },
        gameStars: { $sum: '$stars' },
        gamesPlayed: { $sum: 1 }
      }
    }
  ]);
  console.log('Game ranking aggregate:', gameRanking);

  // 2. Progress completed lessons
  const progressRanking = await Progress.aggregate([
    { $unwind: '$completedLessons' },
    { $match: { 'completedLessons.completedAt': { $gte: startOfMonth } } },
    {
      $group: {
        _id: '$userId',
        lessonStars: { $sum: '$completedLessons.stars' },
        lessonXp: {
          $sum: {
            $cond: [
              { $in: ["$completedLessons.lessonType", ["consonant", "vowel", "number"]] },
              55,
              {
                $cond: [
                  { $in: ["$completedLessons.lessonType", ["spelling", "diacritical", "coeng", "closed_syllable"]] },
                  110,
                  { $multiply: [{ $ifNull: ["$completedLessons.stars", 0] }, 5] }
                ]
              }
            ]
          }
        },
        lessonsCompleted: { $sum: 1 }
      }
    }
  ]);
  console.log('Progress ranking aggregate:', progressRanking);

  // 3. Combine both rankings
  const userMap = {};
  const allUsers = await User.find().select('name avatar level').lean();
  for (const user of allUsers) {
    userMap[user._id.toString()] = {
      userId: user._id,
      name: user.name,
      avatar: user.avatar,
      level: user.level,
      monthlyXp: 0,
      totalStars: 0,
      gamesPlayed: 0
    };
  }

  for (const row of gameRanking) {
    const uid = row._id.toString();
    if (userMap[uid]) {
      userMap[uid].monthlyXp += row.gameXp || 0;
      userMap[uid].totalStars += row.gameStars || 0;
      userMap[uid].gamesPlayed += row.gamesPlayed || 0;
    }
  }

  for (const row of progressRanking) {
    const uid = row._id.toString();
    if (userMap[uid]) {
      userMap[uid].monthlyXp += row.lessonXp || 0;
      userMap[uid].totalStars += row.lessonStars || 0;
      userMap[uid].gamesPlayed += row.lessonsCompleted || 0;
    }
  }

  const list = Object.values(userMap);
  list.sort((a, b) => b.monthlyXp - a.monthlyXp);

  const finalRanking = list.map((item, index) => ({
    rank: index + 1,
    ...item
  }));

  console.log('\n--- COMBINED MONTHLY RANKING ---');
  console.log(JSON.stringify(finalRanking, null, 2));

  process.exit(0);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
