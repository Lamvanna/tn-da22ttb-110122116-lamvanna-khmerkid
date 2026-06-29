/**
 * Script to update user Na ne123 stats (stars, XP, streak, level) for testing
 */
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

async function updateStats() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');

  const User = require('../src/models/User');

  // Find user "Na ne123"
  const user = await User.findOne({ name: 'Na ne123' });
  if (!user) {
    console.log('User not found!');
    process.exit(1);
  }

  console.log(`\nUser: ${user.name} (${user._id})`);
  console.log('--- Before Update ---');
  console.log(`Stars: ${user.stars}`);
  console.log(`XP: ${user.xp}`);
  console.log(`Level: ${user.level}`);
  console.log(`Streak: ${user.streak}`);

  // Update stats
  user.stars = 120;
  user.xp = 850;
  user.level = 3;
  user.streak = 5;
  await user.save();

  console.log('\n--- After Update ---');
  console.log(`Stars: ${user.stars}`);
  console.log(`XP: ${user.xp}`);
  console.log(`Level: ${user.level}`);
  console.log(`Streak: ${user.streak}`);

  await mongoose.disconnect();
}

updateStats().catch(err => {
  console.error(err);
  process.exit(1);
});
