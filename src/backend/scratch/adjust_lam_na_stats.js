/**
 * Script to adjust stars and streak for Lâm Na accounts
 * to 9999 stars and 50 streak days.
 */
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const User = require('../src/models/User');

async function main() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error('MONGO_URI is not set in environment variables');
    process.exit(1);
  }

  console.log('Connecting to MongoDB...');
  await mongoose.connect(uri);
  console.log('Connected!');

  // Emails of target users
  const emails = ['lamvanna2003@gmail.com', 'lamvanna@gmail.com'];

  for (const email of emails) {
    console.log(`\nAdjusting stats for email: ${email}`);

    const user = await User.findOne({ email });
    if (!user) {
      console.log(`❌ User with email ${email} not found. Skipping.`);
      continue;
    }

    user.stars = 9999;
    user.streak = 50;
    user.longestStreak = 50;

    await user.save();
    console.log(`✅ Updated ${user.name}: Stars = ${user.stars}, Streak = ${user.streak}`);
  }

  await mongoose.disconnect();
  console.log('\nSuccessfully adjusted user stats!');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
