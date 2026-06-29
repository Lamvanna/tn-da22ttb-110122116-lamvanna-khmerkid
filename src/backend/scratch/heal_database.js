require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../src/models/User');
const Progress = require('../src/models/Progress');
const Lesson = require('../src/models/Lesson');

// Client-side static lists (to determine correct 0-based index)
const consonants = [
  'ក', 'ខ', 'គ', 'ឃ', 'ង', '📝', 
  'ច', 'ឆ', 'ជ', 'ឈ', 'ញ', '📝', 
  'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ', '📝', 
  'ត', 'ថ', 'ទ', 'ធ', 'ន', '📝', 
  'ប', 'ផ', 'ព', 'ភ', 'ម', '📝', 
  'យ', 'រ', 'ល', 'វ', '📝', 
  'ស', 'ហ', 'ឡ', 'អ', '📝', '📝'
];

const vowels = [
  'អា', 'អิ', 'អី', 'អឹ', 'អឺ', 'អុ', 'អូ', 'អួ', 'អើ', 'អឿ', 'អៀ', 'អេ', 'អែ', 'អៃ', 'អោ', 'អៅ', 'អំ', 'អុំ', 'អះ', 'អាំ', 'អิះ', 'អុះ', 'អេះ', 'អោះ'
];

const numbers = [
  '១', '២', '៣', '៤', '៥'
];

// Historical sequential seeder IDs for consonants
const oldConsonantIds = [
  '6a186e710093e19f53a79d8e', // ក
  '6a186e710093e19f53a79d93', // ខ
  '6a186e710093e19f53a79d98', // គ
  '6a186e710093e19f53a79d9d', // ឃ
  '6a186e710093e19f53a79da2', // ង
  '6a186e710093e19f53a79da7', // ច
  '6a186e710093e19f53a79dac', // ឆ
  '6a186e710093e19f53a79db1', // ជ
  '6a186e710093e19f53a79db6', // ឈ
  '6a186e710093e19f53a79dbb', // ញ
  '6a186e710093e19f53a79dc0', // ដ
  '6a186e710093e19f53a79dc5', // ឋ
  '6a186e710093e19f53a79dca', // ឌ
  '6a186e710093e19f53a79dcf', // ឍ
  '6a186e710093e19f53a79dd4', // ណ
  '6a186e710093e19f53a79dd9', // ត
  '6a186e710093e19f53a79dde', // ថ
  '6a186e710093e19f53a79de3', // ទ
  '6a186e710093e19f53a79de8', // ធ
  '6a186e710093e19f53a79ded', // ន
  '6a186e710093e19f53a79df2', // ប
  '6a186e710093e19f53a79df7', // ផ
  '6a186e710093e19f53a79dfc', // ព
  '6a186e710093e19f53a79e01', // ភ
  '6a186e710093e19f53a79e06', // ម
  '6a186e710093e19f53a79e0b', // យ
  '6a186e710093e19f53a79e10', // រ
  '6a186e710093e19f53a79e15', // ល
  '6a186e710093e19f53a79e1a', // វ
  '6a186e710093e19f53a79e1f', // ស
  '6a186e710093e19f53a79e24', // ហ
  '6a186e710093e19f53a79e29', // ឡ
  '6a186e710093e19f53a79e2e', // អ
];

// Helper to clean and filter consonants list (to get consonant index without tests)
const consonantLettersOnly = consonants.filter(c => c !== '📝');

async function run() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('🔌 Connected to MongoDB.');

    // 1. Fetch all new lessons to map khmerText/order to active ObjectId
    const dbLessons = await Lesson.find({});
    console.log(`Loaded ${dbLessons.length} active lessons from database.`);

    const consonantMap = {}; // khmerText -> id
    const vowelMap = {}; // khmerText -> id
    const numberMap = {}; // khmerText -> id
    const spellingMap = {}; // khmerText -> id
    const closedSyllableMap = {}; // khmerText -> id
    const coengMap = {}; // khmerText -> id
    const sentenceMap = {}; // khmerText -> id
    const vocabularyMap = {}; // khmerText -> id

    dbLessons.forEach(l => {
      const type = l.type;
      const text = l.khmerText;
      if (type === 'consonant') consonantMap[text] = l._id;
      else if (type === 'vowel') vowelMap[text] = l._id;
      else if (type === 'number') numberMap[text] = l._id;
      else if (type === 'spelling') spellingMap[text] = l._id;
      else if (type === 'closed_syllable') closedSyllableMap[text] = l._id;
      else if (type === 'coeng') coengMap[text] = l._id;
      else if (type === 'sentence') sentenceMap[text] = l._id;
      else if (type === 'vocabulary') vocabularyMap[text] = l._id;
    });

    // 2. Fetch all progress logs
    const progressList = await Progress.find({});
    console.log(`Found ${progressList.length} progress documents.`);

    for (const prog of progressList) {
      console.log(`\nProcessing progress for user: ${prog.userId}`);
      const updatedLessons = [];
      const userCompletedLessonIds = new Set();

      for (const l of prog.completedLessons) {
        let newLessonId = l.lessonId;
        let resolvedOrder = l.lessonOrder;
        let resolvedType = l.lessonType;

        // A. If lessonId is an old consonant ObjectId
        if (l.lessonId.startsWith('6a186e71')) {
          const oldIdx = oldConsonantIds.indexOf(l.lessonId);
          if (oldIdx !== -1) {
            const char = consonantLettersOnly[oldIdx];
            newLessonId = consonantMap[char] ? consonantMap[char].toString() : l.lessonId;
            resolvedType = 'consonant';
            resolvedOrder = consonants.indexOf(char); // 0-based client-side index including tests
            console.log(`  [HEAL] Mapped old consonant ObjectId ${l.lessonId} -> ${char} (new ID: ${newLessonId}, order: ${resolvedOrder})`);
          }
        } 
        // B. If lessonId is a custom ID (e.g. consonant_1, vowel_2)
        else if (l.lessonId.includes('_')) {
          const parts = l.lessonId.split('_');
          const type = parts[0];
          const idx = parseInt(parts[1], 10);

          if (!isNaN(idx)) {
            if (type === 'consonant') {
              const char = consonantLettersOnly[idx];
              newLessonId = consonantMap[char] ? consonantMap[char].toString() : l.lessonId;
              resolvedType = 'consonant';
              resolvedOrder = consonants.indexOf(char);
            } else if (type === 'vowel') {
              const char = vowels[idx];
              newLessonId = vowelMap[char] ? vowelMap[char].toString() : l.lessonId;
              resolvedType = 'vowel';
              resolvedOrder = idx;
            } else if (type === 'number') {
              const char = numbers[idx];
              newLessonId = numberMap[char] ? numberMap[char].toString() : l.lessonId;
              resolvedType = 'number';
              resolvedOrder = idx;
            } else {
              // Spelling, writing, reading, coeng etc. — mapping by order directly since they are sequential
              resolvedType = type;
              resolvedOrder = idx;
              // Try to find the corresponding active lesson by order
              const matchingLesson = dbLessons.find(dl => dl.type === type && dl.order === idx + 1);
              if (matchingLesson) {
                newLessonId = matchingLesson._id.toString();
              }
            }
            console.log(`  [HEAL] Mapped custom ID ${l.lessonId} -> type: ${resolvedType}, new ID: ${newLessonId}, order: ${resolvedOrder}`);
          }
        }

        // Add to mapped list
        updatedLessons.push({
          lessonId: newLessonId,
          lessonType: resolvedType || l.lessonType,
          lessonOrder: resolvedOrder,
          stars: l.stars === 0 ? 3 : l.stars, // Default to 3 stars if it was 0 for completion
          isCompleted: true,
          completedAt: l.completedAt
        });

        if (newLessonId.match(/^[0-9a-fA-F]{24}$/)) {
          userCompletedLessonIds.add(newLessonId);
        }
      }

      // Merge and remove duplicates in updatedLessons (take max stars)
      const mergedMap = new Map();
      updatedLessons.forEach(l => {
        const key = `${l.lessonId}_${l.lessonType}`;
        const existing = mergedMap.get(key);
        if (existing) {
          existing.stars = Math.max(existing.stars, l.stars);
          existing.lessonOrder = l.lessonOrder; // keep updated order
        } else {
          mergedMap.set(key, l);
        }
      });
      const uniqueUpdatedLessons = Array.from(mergedMap.values());

      // Save updated progress document
      prog.completedLessons = uniqueUpdatedLessons;
      prog.unlockedLessons = uniqueUpdatedLessons.map(ul => ul.lessonId);
      prog.lastSyncAt = new Date();
      await prog.save();
      console.log(`Saved Progress document for ${prog.userId}. Completed lessons: ${uniqueUpdatedLessons.length}`);

      // 3. Update User model learningProgress.completedLessons and totalLessonsCompleted
      const totalCount = uniqueUpdatedLessons.length;
      const objectIds = Array.from(userCompletedLessonIds).map(id => new mongoose.Types.ObjectId(id));
      
      await User.findByIdAndUpdate(prog.userId, {
        'learningProgress.completedLessons': objectIds,
        'learningProgress.totalLessonsCompleted': totalCount
      });
      console.log(`Updated User document for ${prog.userId}. Total lessons count set to ${totalCount}, populated ObjectIds: ${objectIds.length}`);
    }

    console.log('\n✅ Database healing completed successfully!');
    await mongoose.connection.close();
  } catch (err) {
    console.error('❌ Error during database healing:', err);
    process.exit(1);
  }
}

run();
