const mongoose = require('mongoose');
const GamePlaySession = require('../src/models/GamePlaySession');

async function testModel() {
  console.log('Testing GamePlaySession Mongoose validations...');
  
  // Test case 1: Valid document
  const validSession = new GamePlaySession({
    userId: new mongoose.Types.ObjectId(),
    lessonId: 'lesson-1',
    characterId: 'char-ka',
    totalQuestions: 20,
    correctAnswers: 15,
    wrongAnswers: 5,
    stars: 15,
    bonusStars: 0,
    totalStars: 15,
    xp: 150,
    bonusXP: 0,
    totalXP: 150,
    perfectReward: false
  });

  try {
    await validSession.validate();
    console.log('✅ Valid session validation passed.');
  } catch (err) {
    console.error('❌ Valid session validation failed:', err.message);
  }

  // Test case 2: correctAnswers > 20
  const invalidSession1 = new GamePlaySession({
    userId: new mongoose.Types.ObjectId(),
    lessonId: 'lesson-1',
    characterId: 'char-ka',
    totalQuestions: 20,
    correctAnswers: 21, // invalid
    wrongAnswers: -1, // invalid
    stars: 21,
    bonusStars: 0,
    totalStars: 21,
    xp: 210,
    bonusXP: 0,
    totalXP: 210,
    perfectReward: false
  });

  try {
    await invalidSession1.validate();
    console.log('❌ Invalid session (out of bounds) validation passed unexpectedly.');
  } catch (err) {
    console.log('✅ Invalid session (out of bounds) validation correctly failed:', err.message);
  }

  // Test case 3: correctAnswers + wrongAnswers !== 20
  const invalidSession2 = new GamePlaySession({
    userId: new mongoose.Types.ObjectId(),
    lessonId: 'lesson-1',
    characterId: 'char-ka',
    totalQuestions: 20,
    correctAnswers: 18,
    wrongAnswers: 4, // sum is 22 !== 20
    stars: 18,
    bonusStars: 8,
    totalStars: 26,
    xp: 180,
    bonusXP: 0,
    totalXP: 180,
    perfectReward: false
  });

  try {
    await invalidSession2.validate();
    console.log('❌ Invalid session (incorrect sum) validation passed unexpectedly.');
  } catch (err) {
    console.log('✅ Invalid session (incorrect sum) validation correctly failed:', err.message);
  }

  console.log('Model validation test complete.');
}

testModel();
