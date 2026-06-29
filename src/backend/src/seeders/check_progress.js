'use strict';

require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const mongoose = require('mongoose');
const connectDB = require('../config/database');
const WritingProgress = require('../models/WritingProgress');

async function run() {
  await connectDB();

  try {
    const progress = await WritingProgress.findOne({
      userId: '6a172cf7933f23f39f2100cd',
      character: 'ា'
    });

    if (!progress) {
      console.log('No progress document found for user 6a172cf7933f23f39f2100cd and character ា');
    } else {
      console.log('--- Progress Found ---');
      console.log('User ID:', progress.userId);
      console.log('Character:', progress.character);
      console.log('Best Score:', progress.bestScore);
      console.log('Attempts:', progress.attempts);
      console.log('History:', JSON.stringify(progress.history, null, 2));
    }

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected.');
  }
}

run();
