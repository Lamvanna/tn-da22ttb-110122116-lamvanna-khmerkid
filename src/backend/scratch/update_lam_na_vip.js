/**
 * Script to upgrade users "Lâm Na" (lamvanna2003@gmail.com and lamvanna@gmail.com)
 * to VIP status: unlock all lessons, 99999 stars, high levels, max streaks,
 * and complete all game and writing progress.
 * Optimized using bulkWrite for rapid execution.
 */
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const User = require('../src/models/User');
const Lesson = require('../src/models/Lesson');
const Progress = require('../src/models/Progress');
const StandardCharacter = require('../src/models/StandardCharacter');
const GameProgress = require('../src/models/GameProgress');
const WritingProgress = require('../src/models/WritingProgress');

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
  const emails = [
    'lamvanna2003@gmail.com',
    'lamvanna@gmail.com',
    'admin@khmerkid.com',
    'lamna2003@gmail.com'
  ];
  
  // 1. Fetch all lessons and standard characters
  console.log('Fetching lessons and standard characters...');
  const lessons = await Lesson.find({ isActive: true });
  const chars = await StandardCharacter.find({ isActive: true });
  console.log(`Found ${lessons.length} active lessons and ${chars.length} active characters.`);

  if (lessons.length === 0) {
    console.warn('⚠️ No active lessons found. Progress matching might be incomplete.');
  }

  for (const email of emails) {
    console.log(`\n=============================================`);
    console.log(`Processing user with email: ${email}`);
    console.log(`=============================================`);

    const user = await User.findOne({ email });
    if (!user) {
      console.log(`❌ User with email ${email} not found. Skipping.`);
      continue;
    }

    console.log(`Found user: ${user.name} (${user._id})`);

    // 2. Update core user model attributes
    user.stars = 99999;
    user.xp = 150000;
    user.level = 60;
    user.streak = 365;
    user.longestStreak = 365;
    user.rank = 1;
    
    // Set inventory items
    user.inventory = {
      hints: 99,
      timePowerups: 99,
      livesPowerups: 99,
      doubleScorePowerups: 99,
      hintsLastReg: Date.now(),
      timePowerupsLastReg: Date.now(),
      livesPowerupsLastReg: Date.now(),
      doubleScorePowerupsLastReg: Date.now(),
    };

    // Update learning progress summary
    user.learningProgress = {
      totalLessonsCompleted: lessons.length,
      totalGamesPlayed: lessons.length * 4,
      totalStudyTime: 5000,
      listeningLevel: 100,
      speakingLevel: 100,
      readingLevel: 100,
      writingLevel: 100,
      writingPracticeCount: chars.length * 10,
      readingCorrectCount: lessons.length * 20,
      speakingSuccessCount: lessons.length * 10,
      listeningCompleteCount: lessons.length * 5,
      readingLessonsCompleted: lessons.length,
      completedLessons: lessons.map(l => l._id),
      weakSkills: [],
    };

    console.log('Saving updated user document...');
    await user.save();
    console.log('✅ User document updated!');

    // 3. Upsert Progress document
    console.log('Creating/updating Progress document...');
    const progressData = {
      userId: user._id,
      completedLessons: lessons.map(l => ({
        lessonId: l._id.toString(),
        lessonType: l.type,
        lessonOrder: l.order || 0,
        stars: 3,
        isCompleted: true,
        completedAt: new Date(),
      })),
      unlockedLessons: lessons.map(l => l._id.toString()),
      achievements: ['first_steps', 'streak_champion', 'khmer_master', 'perfect_scores'],
      lastSyncAt: new Date(),
    };

    await Progress.findOneAndUpdate(
      { userId: user._id },
      progressData,
      { upsert: true, new: true }
    );
    console.log('✅ Progress document updated!');

    // 4. Create/update GameProgress for all lessons & characters using bulkWrite
    console.log('Preparing GameProgress bulk operations...');
    const gpOps = [];
    
    for (const lesson of lessons) {
      for (const char of chars) {
        const isMatch = lesson.khmerText.includes(char.character) || lesson.title.includes(char.character);
        if (isMatch || lesson.type === 'consonant' || lesson.type === 'vowel') {
          gpOps.push({
            updateOne: {
              filter: { userId: user._id, lessonId: lesson._id.toString(), characterId: char.character },
              update: {
                $set: {
                  unlocked: true,
                  game1Completed: true,
                  game1Score: 100,
                  game1Stars: 3,
                  game1Duration: 20,
                  game1CompletedAt: new Date(),
                  
                  game2Completed: true,
                  game2Score: 100,
                  game2Stars: 3,
                  game2Duration: 25,
                  game2WrongAnswers: 0,
                  game2CompletedAt: new Date(),
                  
                  game3Completed: true,
                  game3Score: 100,
                  game3Stars: 3,
                  game3Duration: 30,
                  game3Attempts: 1,
                  game3CompletedAt: new Date(),
                  
                  game4Completed: true,
                  game4Score: 100,
                  game4Stars: 3,
                  game4Confidence: 1.0,
                  game4Similarity: 100,
                  game4RecognizedText: char.character,
                  game4CompletedAt: new Date(),
                  
                  totalScore: 400,
                  totalStars: 12,
                  xp: 200,
                }
              },
              upsert: true
            }
          });
        }
      }
    }
    
    if (gpOps.length > 0) {
      console.log(`Executing bulkWrite for ${gpOps.length} GameProgress records...`);
      const result = await GameProgress.bulkWrite(gpOps);
      console.log(`✅ GameProgress bulkWrite complete: ${result.upsertedCount} upserted, ${result.modifiedCount} modified`);
    }

    // 5. Create/update WritingProgress for all standard characters using bulkWrite
    console.log('Preparing WritingProgress bulk operations...');
    const wpOps = chars.map(char => ({
      updateOne: {
        filter: { userId: user._id, character: char.character },
        update: {
          $set: {
            bestScore: 100,
            stars: 3,
            attempts: 10,
            isCompleted: true,
            history: [
              {
                score: 100,
                shapeScore: 100,
                directionScore: 100,
                strokeCountScore: 100,
                errors: [],
                feedback: "Tuyệt vời! nét vẽ hoàn hảo.",
                analyzedAt: new Date(),
              }
            ]
          }
        },
        upsert: true
      }
    }));

    if (wpOps.length > 0) {
      console.log(`Executing bulkWrite for ${wpOps.length} WritingProgress records...`);
      const result = await WritingProgress.bulkWrite(wpOps);
      console.log(`✅ WritingProgress bulkWrite complete: ${result.upsertedCount} upserted, ${result.modifiedCount} modified`);
    }
  }

  await mongoose.disconnect();
  console.log('\nAll operations completed successfully!');
}

main().catch(err => {
  console.error('Error during execution:', err);
  process.exit(1);
});
