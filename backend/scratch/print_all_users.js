require('dotenv').config();
const mongoose = require('mongoose');
const Progress = require('../src/models/Progress');
const User = require('../src/models/User');

async function run() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const users = await User.find({});
    console.log(`Found ${users.length} users in database.`);
    for (const u of users) {
      const prog = await Progress.findOne({ userId: u._id });
      console.log(`- User: ${u.name} (${u.email})`);
      console.log(`  Completed lessons count: ${prog ? prog.completedLessons.length : 0}`);
      if (prog) {
        const types = {};
        prog.completedLessons.forEach(l => {
          types[l.lessonType] = (types[l.lessonType] || 0) + 1;
        });
        console.log(`  Breakdown:`, types);
      }
    }
    await mongoose.connection.close();
  } catch (err) {
    console.error(err);
  }
}
run();
