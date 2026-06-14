/**
 * ========================================
 * Test Question Seeder
 * ========================================
 */

require('dotenv').config();
const mongoose = require('mongoose');
const TestQuestion = require('../models/TestQuestion');

const testQuestions = [
  // --- NHÓM 1 (Bài 1-5) ---
  {
    question: 'Chữ "ក" đọc là gì?',
    options: ['ka', 'kha', 'ko', 'kho'],
    answer: 'ka',
    testRange: '1-5',
  },
  {
    question: 'Chữ "ខ" đọc là gì?',
    options: ['kha', 'ka', 'ngo', 'kho'],
    answer: 'kha',
    testRange: '1-5',
  },
  {
    question: 'Chữ "គ" đọc là gì?',
    options: ['ko', 'kho', 'ka', 'ngo'],
    answer: 'ko',
    testRange: '1-5',
  },
  {
    question: 'Chữ "ឃ" đọc là gì?',
    options: ['kho', 'ko', 'kha', 'ngo'],
    answer: 'kho',
    testRange: '1-5',
  },
  {
    question: 'Chữ "ង" đọc là gì?',
    options: ['ngo', 'no', 'ko', 'kho'],
    answer: 'ngo',
    testRange: '1-5',
  },
  {
    question: 'Chữ nào phát âm là "ka"?',
    options: ['ក', 'ខ', 'គ', 'ឃ'],
    answer: 'ក',
    testRange: '1-5',
  },
  {
    question: 'Chữ nào phát âm là "kha"?',
    options: ['ខ', 'ក', 'គ', 'ឃ'],
    answer: 'ខ',
    testRange: '1-5',
  },
  {
    question: 'Chữ nào phát âm là "ngo"?',
    options: ['ង', 'គ', 'ឃ', 'ខ'],
    answer: 'ង',
    testRange: '1-5',
  },

  // --- NHÓM 2 (Bài 6-10) ---
  {
    question: 'Chữ "ច" đọc là gì?',
    options: ['cho', 'chhor', 'ko', 'kho'],
    answer: 'cho',
    testRange: '6-10',
  },
  {
    question: 'Chữ "ឆ" đọc là gì?',
    options: ['chhor', 'cho', 'nhor', 'ngo'],
    answer: 'chhor',
    testRange: '6-10',
  },
  {
    question: 'Chữ "ញ" đọc là gì?',
    options: ['nhor', 'yo', 'ngo', 'ko'],
    answer: 'nhor',
    testRange: '6-10',
  },
  {
    question: 'Chữ nào phát âm là "cho" (hàng ô)?',
    options: ['ជ', 'ច', 'ឆ', 'ញ'],
    answer: 'ជ',
    testRange: '6-10',
  },
  {
    question: 'Chữ nào phát âm là "chhor" (hàng o)?',
    options: ['ឆ', 'ឈ', 'ច', 'ជ'],
    answer: 'ឆ',
    testRange: '6-10',
  },

  // --- NHÓM 3 (Bài 13-17) ---
  {
    question: 'Chữ "ដ" đọc là gì?',
    options: ['da', 'tha', 'do', 'na'],
    answer: 'da',
    testRange: '13-17',
  },
  {
    question: 'Chữ "ណ" đọc là gì?',
    options: ['na', 'no', 'da', 'tho'],
    answer: 'na',
    testRange: '13-17',
  },
  {
    question: 'Chữ nào phát âm là "do"?',
    options: ['ឌ', 'ដ', 'ឋ', 'ឍ'],
    answer: 'ឌ',
    testRange: '13-17',
  },
  {
    question: 'Chữ nào phát âm là "tha"?',
    options: ['ឋ', 'ឍ', 'ឌ', 'ដ'],
    answer: 'ឋ',
    testRange: '13-17',
  },

  // --- NHÓM 4 (Bài 19-23) ---
  {
    question: 'Chữ "ត" đọc là gì?',
    options: ['ta', 'tha', 'to', 'no'],
    answer: 'ta',
    testRange: '19-23',
  },
  {
    question: 'Chữ "ន" đọc là gì?',
    options: ['no', 'na', 'to', 'tho'],
    answer: 'no',
    testRange: '19-23',
  },
  {
    question: 'Chữ nào phát âm là "to"?',
    options: ['ទ', 'ត', 'ថ', 'ធ'],
    answer: 'ទ',
    testRange: '19-23',
  },

  // --- NHÓM 5 (Bài 25-29) ---
  {
    question: 'Chữ "ប" đọc là gì?',
    options: ['ba', 'pha', 'po', 'mo'],
    answer: 'ba',
    testRange: '25-29',
  },
  {
    question: 'Chữ "ម" đọc là gì?',
    options: ['mo', 'po', 'pho', 'ba'],
    answer: 'mo',
    testRange: '25-29',
  },
  {
    question: 'Chữ nào phát âm là "po"?',
    options: ['ព', 'ប', 'ផ', 'ភ'],
    answer: 'ព',
    testRange: '25-29',
  },

  // --- NHÓM 6 (Bài 31-34) ---
  {
    question: 'Chữ "យ" đọc là gì?',
    options: ['yo', 'ro', 'lo', 'vo'],
    answer: 'yo',
    testRange: '31-34',
  },
  {
    question: 'Chữ "វ" đọc là gì?',
    options: ['vo', 'lo', 'ro', 'yo'],
    answer: 'vo',
    testRange: '31-34',
  },
  {
    question: 'Chữ nào phát âm là "ro"?',
    options: ['រ', 'ល', 'វ', 'ย'],
    answer: 'រ',
    testRange: '31-34',
  },

  // --- NHÓM 7 (Bài 36-39) ---
  {
    question: 'Chữ "ស" đọc là gì?',
    options: ['sa', 'ha', 'la', 'a'],
    answer: 'sa',
    testRange: '36-39',
  },
  {
    question: 'Chữ "អ" đọc là gì?',
    options: ['a', 'la', 'ha', 'sa'],
    answer: 'a',
    testRange: '36-39',
  },
  {
    question: 'Chữ nào phát âm là "ha"?',
    options: ['ហ', 'ស', 'ឡ', 'អ'],
    answer: 'ហ',
    testRange: '36-39',
  },

  // --- BÀI 41: KIỂM TRA TỔNG HỢP (Bài 1-40) ---
  {
    question: 'Chữ "ក" đọc là gì?',
    options: ['ka', 'ko', 'kha', 'kho'],
    answer: 'ka',
    testRange: '1-40',
  },
  {
    question: 'Chữ "ខ" đọc là gì?',
    options: ['kha', 'ko', 'ka', 'kho'],
    answer: 'kha',
    testRange: '1-40',
  },
  {
    question: 'Chữ "គ" đọc là gì?',
    options: ['ko', 'ka', 'kho', 'kha'],
    answer: 'ko',
    testRange: '1-40',
  },
  {
    question: 'Chữ "ឃ" đọc là gì?',
    options: ['kho', 'ko', 'kha', 'ka'],
    answer: 'kho',
    testRange: '1-40',
  },
  {
    question: 'Chữ "ង" đọc là gì?',
    options: ['ngo', 'no', 'ngo', 'nhor'],
    answer: 'ngo',
    testRange: '1-40',
  },
];

const seedTestQuestions = async () => {
  try {
    console.log('⏳ Seeding Test Questions into Database...');

    // Clear existing test questions
    const deleteResult = await TestQuestion.deleteMany({});
    console.log(`🧹 Cleared ${deleteResult.deletedCount} old test questions.`);

    // Insert new test questions
    const insertedQuestions = await TestQuestion.insertMany(testQuestions);
    console.log(`🎉 Successfully seeded ${insertedQuestions.length} new test questions!`);

    return insertedQuestions;
  } catch (error) {
    console.error('❌ Error seeding test questions:', error.message);
    throw error;
  }
};

// If run directly
if (require.main === module) {
  mongoose.connect(process.env.MONGO_URI)
    .then(() => {
      console.log('🔌 Connected to MongoDB for seeding test questions.');
      return seedTestQuestions();
    })
    .then(() => {
      console.log('🔌 Closing connection...');
      return mongoose.connection.close();
    })
    .then(() => {
      console.log('👋 Seeder finished successfully.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Fatal error in seeder:', err);
      process.exit(1);
    });
}

module.exports = seedTestQuestions;
