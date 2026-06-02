const mongoose = require('mongoose');
require('dotenv').config();

const userSchema = new mongoose.Schema({
  name: String,
  email: String,
  xp: { type: Number, default: 0 },
  stars: { type: Number, default: 0 },
  level: { type: Number, default: 1 },
  avatar: { type: String, default: '' },
  role: { type: String, default: 'user' },
  authProvider: { type: String, default: 'local' },
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

  // 1. Clear old game results
  console.log('Clearing old gameresults...');
  await GameResult.deleteMany({});
  console.log('Old game results cleared.');

  // 2. Comprehensive active student list
  const students = [
    {
      id: "6a172cfc933f23f39f2100d1", // Existing
      name: "Văn Na Lâm",
      email: "lamna01633661157@gmail.com",
      xp: 1197,
      stars: 252,
      level: 3,
      avatar: "https://lh3.googleusercontent.com/a/ACg8ocJREvQnFatsR8TqOF4JbUSd1RQnVrR1iQrq3bYrBUKi2Y9VpzAm=s96-c",
      weeklyXp: 1100,
      weeklyStars: 230
    },
    {
      id: "6a172cf7933f23f39f2100cd", // Existing (Current user)
      name: "Na Dep Trai",
      email: "hero01633661157@gmail.com",
      xp: 1092,
      stars: 228,
      level: 3,
      avatar: "image/Đại diện.png",
      weeklyXp: 980,
      weeklyStars: 210
    },
    {
      id: "6a1884d86e1f86922a0f140e", // Existing
      name: "Minh Anh",
      email: "lam011@gmail.com",
      xp: 1010,
      stars: 200,
      level: 3,
      avatar: "image/Đại diện.png",
      weeklyXp: 920,
      weeklyStars: 180
    },
    {
      id: "6a1725d349651ab384344423", // Existing
      name: "Nguyễn Tuấn Kiệt",
      email: "kiet123@gmail.com",
      xp: 900,
      stars: 180,
      level: 2,
      avatar: "image/Đại diện.png",
      weeklyXp: 800,
      weeklyStars: 160
    },
    {
      id: "6a1885076e1f86922a0f1412", // Existing
      name: "Gia Bảo",
      email: "lamna123@gmail.com",
      xp: 820,
      stars: 165,
      level: 2,
      avatar: "image/Đại diện.png",
      weeklyXp: 750,
      weeklyStars: 150
    },
    {
      id: "6a1883a26e1f86922a0f13c7", // Existing
      name: "Lâm Na",
      email: "lamvanna2003@gmail.com",
      xp: 750,
      stars: 155,
      level: 2,
      avatar: "image/Đại diện.png",
      weeklyXp: 680,
      weeklyStars: 140
    },
    {
      id: "6a1887126e1f86922a0f14d7", // Existing
      name: "Quỳnh Chi",
      email: "lamna016336611@gmail.com",
      xp: 680,
      stars: 140,
      level: 2,
      avatar: "image/Đại diện.png",
      weeklyXp: 600,
      weeklyStars: 120
    },
    {
      id: "6a188a126e1f86922a0f14fa", // New
      name: "Phúc Thịnh",
      email: "thinh@gmail.com",
      xp: 550,
      stars: 110,
      level: 1,
      avatar: "image/Đại diện.png",
      weeklyXp: 500,
      weeklyStars: 100
    },
    {
      id: "6a188b126e1f86922a0f14fb", // New
      name: "Hoàng Bách",
      email: "bach@gmail.com",
      xp: 480,
      stars: 95,
      level: 1,
      avatar: "image/Đại diện.png",
      weeklyXp: 420,
      weeklyStars: 85
    },
    {
      id: "6a188c126e1f86922a0f14fc", // New
      name: "Thảo Chi",
      email: "thaochi@gmail.com",
      xp: 400,
      stars: 80,
      level: 1,
      avatar: "image/Đại diện.png",
      weeklyXp: 350,
      weeklyStars: 70
    }
  ];

  // 3. Upsert students & insert their game results
  for (const student of students) {
    console.log(`Processing student: ${student.name}...`);
    
    // Find if user already exists
    let user = await User.findById(student.id);
    if (!user) {
      console.log(`  Creating new user record for ${student.name}...`);
      user = await User.create({
        _id: new mongoose.Types.ObjectId(student.id),
        name: student.name,
        email: student.email,
        xp: student.xp,
        stars: student.stars,
        level: student.level,
        avatar: student.avatar,
        role: 'user',
        authProvider: 'local'
      });
    } else {
      console.log(`  Updating existing user record for ${student.name}...`);
      user.name = student.name;
      user.xp = student.xp;
      user.stars = student.stars;
      user.level = student.level;
      if (!user.avatar) {
        user.avatar = student.avatar;
      }
      await user.save();
    }

    // Insert GameResult for weekly and monthly rankings (dated TODAY)
    console.log(`  Inserting game result for ${student.name}...`);
    await GameResult.create({
      userId: user._id,
      gameType: 'catch_letter',
      score: student.weeklyXp * 10,
      stars: student.weeklyStars,
      level: student.level,
      time: 45,
      correctAnswers: 10,
      totalQuestions: 10,
      xpEarned: student.weeklyXp,
      createdAt: new Date() // Current date/time so it counts for this week and month
    });
  }

  console.log('🏁 Database seeding of leaderboard data completed successfully!');
  await mongoose.disconnect();
  console.log('Disconnected!');
}

seed().catch(console.error);
