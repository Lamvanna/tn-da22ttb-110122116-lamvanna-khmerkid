require('dotenv').config();
const mongoose = require('mongoose');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  
  // Find Na ne123
  const User = require('../src/models/User');
  const Progress = require('../src/models/Progress');
  
  const user = await User.findOne({ name: 'Na ne123' });
  console.log('--- USER Na ne123 ---');
  console.log(user);
  
  if (user) {
    const progress = await Progress.findOne({ userId: user._id });
    console.log('--- PROGRESS FOR Na ne123 ---');
    console.log(JSON.stringify(progress, null, 2));
  }
  
  // Find recent progress updates for any user
  const recentProgress = await Progress.find({
    updatedAt: { $gte: new Date(Date.now() - 30 * 60 * 1000) }
  });
  console.log('--- RECENT PROGRESS (LAST 30 MINS) ---');
  console.log(JSON.stringify(recentProgress, null, 2));

  process.exit(0);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
