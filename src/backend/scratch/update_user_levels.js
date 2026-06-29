require('dotenv').config();
const mongoose = require('mongoose');
const { calculateLevel } = require('../src/utils/helpers');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to DB');

  const User = require('../src/models/User');

  const users = await User.find();
  console.log(`Found ${users.length} users to check/update.`);

  for (const user of users) {
    const correctLevelInfo = calculateLevel(user.xp);
    if (user.level !== correctLevelInfo.level) {
      console.log(`Updating ${user.name}: level ${user.level} -> ${correctLevelInfo.level} (XP: ${user.xp})`);
      user.level = correctLevelInfo.level;
      await user.save();
    } else {
      console.log(`User ${user.name} is already correct at level ${user.level} (XP: ${user.xp})`);
    }
  }

  console.log('Update completed successfully.');
  process.exit(0);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
