require('dotenv').config();
const mongoose = require('mongoose');
const Progress = require('../src/models/Progress');
const User = require('../src/models/User');

async function run() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const user = await User.findOne({ email: 'hero01633661157@gmail.com' });
    if (!user) {
      console.log('User not found');
      return;
    }
    console.log('User ID:', user._id);
    const prog = await Progress.findOne({ userId: user._id });
    if (!prog) {
      console.log('Progress not found');
      return;
    }
    console.log('All completed lessons count:', prog.completedLessons.length);
    prog.completedLessons.forEach(l => {
      console.log(`- ID: ${l.lessonId}, Type: ${l.lessonType}, Order: ${l.lessonOrder}, Stars: ${l.stars}`);
    });
    await mongoose.connection.close();
  } catch (err) {
    console.error(err);
  }
}
run();
