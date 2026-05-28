const mongoose = require('mongoose');
require('dotenv').config();

const userSchema = new mongoose.Schema({
  name: String,
  email: String,
  xp: { type: Number, default: 0 },
  stars: { type: Number, default: 0 }
}, { strict: false });
const User = mongoose.model('User', userSchema, 'users');

const gameResultSchema = new mongoose.Schema({
  userId: mongoose.Schema.Types.ObjectId,
  gameType: String,
  score: Number,
  stars: Number,
  level: Number,
  time: Number,
  correctAnswers: Number,
  totalQuestions: Number,
  xpEarned: Number,
  createdAt: { type: Date, default: Date.now }
}, { timestamps: true });
const GameResult = mongoose.model('GameResult', gameResultSchema, 'gameresults');

async function seed() {
  const uri = process.env.MONGO_URI || "mongodb+srv://admin:PCO6NePc2Gmcifzt@lamv.tzc1slv.mongodb.net/khmerkid";
  console.log('Connecting to MongoDB...');
  await mongoose.connect(uri);
  console.log('Connected!');

  // 1. Clear existing game results
  console.log('Clearing old gameresults...');
  await GameResult.deleteMany({});
  console.log('Cleared!');

  // 2. Define user IDs
  const usersInfo = [
    { id: "6a1725d349651ab384344423", xp: 150, stars: 3, name: "Nguyễn Tuấn Kiệt" },
    { id: "6a172cfc933f23f39f2100d1", xp: 120, stars: 1, name: "Văn Na Lâm" },
    { id: "6a172cf7933f23f39f2100cd", xp: 100, stars: 2, name: "Ro He" }
  ];

  // 3. Insert fresh weekly/monthly game results for each user
  for (const info of usersInfo) {
    console.log(`Seeding gameresult for ${info.name}...`);
    await GameResult.create({
      userId: new mongoose.Types.ObjectId(info.id),
      gameType: 'catch_letter',
      score: info.xp * 10,
      stars: info.stars,
      level: 1,
      time: 45,
      correctAnswers: 10,
      totalQuestions: 10,
      xpEarned: info.xp,
      createdAt: new Date() // Current date so it counts for weekly/monthly!
    });

    // 4. Update the user's total xp and stars in users collection
    console.log(`Updating user ${info.name} total xp and stars...`);
    await User.findByIdAndUpdate(info.id, {
      xp: info.xp,
      stars: info.stars
    });
  }

  console.log('Successfully seeded GameResults and updated Users!');
  await mongoose.disconnect();
  console.log('Disconnected!');
}

seed().catch(console.error);
