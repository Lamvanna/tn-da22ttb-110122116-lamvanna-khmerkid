/**
 * ========================================
 * Lesson Seeder
 * ========================================
 * 
 * Seeds 33 Consonants, 24 Vowels, and 10 basic Vocabulary items
 * with high quality structures for reading, listening, writing, and speaking.
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Lesson = require('../models/Lesson');
const { LESSON_TYPES, DIFFICULTY } = require('../constants');

const consonantsList = [
  { khmer: 'ក', romanized: 'ka', meaning: 'Chữ Ka (phụ âm nhóm a)', pronunciation: 'kâ' },
  { khmer: 'ខ', romanized: 'kha', meaning: 'Chữ Kha (phụ âm nhóm a)', pronunciation: 'khâ' },
  { khmer: 'គ', romanized: 'ko', meaning: 'Chữ Ko (phụ âm nhóm o)', pronunciation: 'kô' },
  { khmer: 'ឃ', romanized: 'kho', meaning: 'Chữ Kho (phụ âm nhóm o)', pronunciation: 'khô' },
  { khmer: 'ង', romanized: 'ngo', meaning: 'Chữ Ngo (phụ âm nhóm o)', pronunciation: 'ngô' },
  { khmer: 'ច', romanized: 'cha', meaning: 'Chữ Cha (phụ âm nhóm a)', pronunciation: 'châ' },
  { khmer: 'ឆ', romanized: 'chha', meaning: 'Chữ Chha (phụ âm nhóm a)', pronunciation: 'chhhâ' },
  { khmer: 'ជ', romanized: 'cho', meaning: 'Chữ Cho (phụ âm nhóm o)', pronunciation: 'chô' },
  { khmer: 'ឈ', romanized: 'chho', meaning: 'Chữ Chho (phụ âm nhóm o)', pronunciation: 'chhô' },
  { khmer: 'ញ', romanized: 'nho', meaning: 'Chữ Nho (phụ âm nhóm o)', pronunciation: 'nhô' },
  { khmer: 'ដ', romanized: 'da', meaning: 'Chữ Da (phụ âm nhóm a)', pronunciation: 'dâ' },
  { khmer: 'ឋ', romanized: 'tha', meaning: 'Chữ Tha (phụ âm nhóm a)', pronunciation: 'thâ' },
  { khmer: 'ឌ', romanized: 'do', meaning: 'Chữ Do (phụ âm nhóm o)', pronunciation: 'dô' },
  { khmer: 'ឍ', romanized: 'tho', meaning: 'Chữ Tho (phụ âm nhóm o)', pronunciation: 'thô' },
  { khmer: 'ណ', romanized: 'na', meaning: 'Chữ Na (phụ âm nhóm a)', pronunciation: 'nâ' },
  { khmer: 'ត', romanized: 'ta', meaning: 'Chữ Ta (phụ âm nhóm a)', pronunciation: 'tâ' },
  { khmer: 'ថ', romanized: 'tha', meaning: 'Chữ Tha (phụ âm nhóm a)', pronunciation: 'thâ' },
  { khmer: 'ទ', romanized: 'to', meaning: 'Chữ To (phụ âm nhóm o)', pronunciation: 'tô' },
  { khmer: 'ធ', romanized: 'tho', meaning: 'Chữ Tho (phụ âm nhóm o)', pronunciation: 'thô' },
  { khmer: 'ន', romanized: 'no', meaning: 'Chữ No (phụ âm nhóm o)', pronunciation: 'nô' },
  { khmer: 'ប', romanized: 'ba', meaning: 'Chữ Ba (phụ âm nhóm a)', pronunciation: 'bâ' },
  { khmer: 'ផ', romanized: 'pha', meaning: 'Chữ Pha (phụ âm nhóm a)', pronunciation: 'phâ' },
  { khmer: 'ព', romanized: 'po', meaning: 'Chữ Po (phụ âm nhóm o)', pronunciation: 'pô' },
  { khmer: 'ភ', romanized: 'pho', meaning: 'Chữ Pho (phụ âm nhóm o)', pronunciation: 'phô' },
  { khmer: 'ម', romanized: 'mo', meaning: 'Chữ Mo (phụ âm nhóm o)', pronunciation: 'mô' },
  { khmer: 'យ', romanized: 'yo', meaning: 'Chữ Yo (phụ âm nhóm o)', pronunciation: 'yô' },
  { khmer: 'រ', romanized: 'ro', meaning: 'Chữ Ro (phụ âm nhóm o)', pronunciation: 'rô' },
  { khmer: 'ល', romanized: 'lo', meaning: 'Chữ Lo (phụ âm nhóm o)', pronunciation: 'lô' },
  { khmer: 'វ', romanized: 'vo', meaning: 'Chữ Vo (phụ âm nhóm o)', pronunciation: 'vô' },
  { khmer: 'ស', romanized: 'sa', meaning: 'Chữ Sa (phụ âm nhóm a)', pronunciation: 'sâ' },
  { khmer: 'ហ', romanized: 'ha', meaning: 'Chữ Ha (phụ âm nhóm a)', pronunciation: 'hâ' },
  { khmer: 'ឡ', romanized: 'la', meaning: 'Chữ La (phụ âm nhóm a)', pronunciation: 'lâ' },
  { khmer: 'អ', romanized: 'aq', meaning: 'Chữ Aq (phụ âm nhóm a)', pronunciation: 'â' },
];

const vowelsList = [
  { khmer: 'ា', romanized: 'a', meaning: 'Nguyên âm A', pronunciation: 'srak a' },
  { khmer: 'ិ', romanized: 'i', meaning: 'Nguyên âm I', pronunciation: 'srak i' },
  { khmer: 'ី', romanized: 'ii', meaning: 'Nguyên âm Ii', pronunciation: 'srak ii' },
  { khmer: 'ឹ', romanized: 'ue', meaning: 'Nguyên âm Ue', pronunciation: 'srak ue' },
  { khmer: 'ឺ', romanized: 'uee', meaning: 'Nguyên âm Uee', pronunciation: 'srak uee' },
  { khmer: 'ុ', romanized: 'u', meaning: 'Nguyên âm U', pronunciation: 'srak u' },
  { khmer: 'ូ', romanized: 'uu', meaning: 'Nguyên âm Uu', pronunciation: 'srak uu' },
  { khmer: 'ួ', romanized: 'uo', meaning: 'Nguyên âm Uo', pronunciation: 'srak uo' },
  { khmer: 'ើ', romanized: 'oeu', meaning: 'Nguyên âm Oeu', pronunciation: 'srak oeu' },
  { khmer: 'ឿ', romanized: 'uea', meaning: 'Nguyên âm Uea', pronunciation: 'srak uea' },
  { khmer: 'ៀ', romanized: 'ie', meaning: 'Nguyên âm Ie', pronunciation: 'srak ie' },
  { khmer: 'េ', romanized: 'e', meaning: 'Nguyên âm E', pronunciation: 'srak e' },
  { khmer: 'ែ', romanized: 'ae', meaning: 'Nguyên âm Ae', pronunciation: 'srak ae' },
  { khmer: 'ៃ', romanized: 'ai', meaning: 'Nguyên âm Ai', pronunciation: 'srak ai' },
  { khmer: 'ោ', romanized: 'ao', meaning: 'Nguyên âm Ao', pronunciation: 'srak ao' },
  { khmer: 'ៅ', romanized: 'au', meaning: 'Nguyên âm Au', pronunciation: 'srak au' },
  { khmer: 'ុំ', romanized: 'um', meaning: 'Nguyên âm Um', pronunciation: 'srak um' },
  { khmer: 'ំ', romanized: 'am', meaning: 'Nguyên âm Am', pronunciation: 'srak am' },
  { khmer: 'ាំ', romanized: 'am-s', meaning: 'Nguyên âm Ams', pronunciation: 'srak ams' },
  { khmer: 'ះ', romanized: 'ah', meaning: 'Nguyên âm Ah', pronunciation: 'srak ah' },
  { khmer: 'ុះ', romanized: 'uh', meaning: 'Nguyên âm Uh', pronunciation: 'srak uh' },
  { khmer: 'េះ', romanized: 'eh', meaning: 'Nguyên âm Eh', pronunciation: 'srak eh' },
  { khmer: 'ោះ', romanized: 'oh', meaning: 'Nguyên âm Oh', pronunciation: 'srak oh' },
  { khmer: 'ៈ', romanized: 'aq', meaning: 'Nguyên âm Aq', pronunciation: 'srak aq' },
];

const vocabularyList = [
  { khmer: 'ផ្កា', romanized: 'pka', meaning: 'Hoa (Bông hoa)', pronunciation: 'phka', category: 'Cây cối' },
  { khmer: 'ផ្ទះ', romanized: 'phteah', meaning: 'Nhà (Ngôi nhà)', pronunciation: 'ph-teah', category: 'Gia đình' },
  { khmer: 'ឆ្មា', romanized: 'chhma', meaning: 'Mèo', pronunciation: 'chhma', category: 'Động vật' },
  { khmer: 'ឆ្កែ', romanized: 'chgai', meaning: 'Chó', pronunciation: 'ch-kai', category: 'Động vật' },
  { khmer: 'ទឹក', romanized: 'teuk', meaning: 'Nước', pronunciation: 'teuk', category: 'Đồ uống' },
  { khmer: 'បាយ', romanized: 'bai', meaning: 'Cơm', pronunciation: 'bai', category: 'Thức ăn' },
  { khmer: 'សាលារៀន', romanized: 'sala rien', meaning: 'Trường học', pronunciation: 'sala rien', category: 'Xã hội' },
  { khmer: 'គ្រូបង្រៀន', romanized: 'kru bongrien', meaning: 'Thầy cô giáo', pronunciation: 'kru bong-rien', category: 'Con người' },
  { khmer: 'សៀវភៅ', romanized: 'siev phou', meaning: 'Sách', pronunciation: 'siev phou', category: 'Học tập' },
  { khmer: 'ប៊ិច', romanized: 'bech', meaning: 'Bút viết', pronunciation: 'bech', category: 'Học tập' },
];

const seedLessons = async () => {
  try {
    console.log('⏳ Seeding Lessons into Database...');
    const deleteResult = await Lesson.deleteMany({});
    console.log(`🧹 Cleared ${deleteResult.deletedCount} old lessons.`);

    const lessonsToInsert = [];
    let orderCounter = 1;

    // 1. Seed Consonants
    for (const item of consonantsList) {
      lessonsToInsert.push({
        title: `Phụ âm: ${item.khmer}`,
        description: `Học cách phát âm và viết phụ âm ${item.khmer} (${item.romanized})`,
        type: LESSON_TYPES.CONSONANT,
        khmerText: item.khmer,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.pronunciation,
        difficulty: DIFFICULTY.BEGINNER,
        order: orderCounter++,
        category: 'Bảng chữ cái',
        isActive: true,
        // Writing support (stroke order instructions)
        strokeOrder: [
          { step: 1, instruction: 'Bắt đầu từ nét móc tròn phía dưới bên trái.', svgPath: 'M 10 90 Q 20 50 30 90' },
          { step: 2, instruction: 'Vẽ nét đứng lên phía trên.', svgPath: 'M 30 90 L 30 20' },
          { step: 3, instruction: 'Tạo vòng cung đầu chữ hướng sang phải rồi kéo thẳng xuống.', svgPath: 'M 30 20 C 50 10 70 30 70 90' }
        ],
        // Listening question support
        questions: [
          {
            question: `Phụ âm "${item.khmer}" có phiên âm Latinh là gì?`,
            options: [item.romanized, 'cho', 'nho', 'mo'],
            correctAnswer: 0,
            explanation: `Phụ âm "${item.khmer}" có phiên âm Latinh chính xác là "${item.romanized}".`
          }
        ]
      });
    }

    // 2. Seed Vowels
    for (const item of vowelsList) {
      lessonsToInsert.push({
        title: `Nguyên âm: ${item.khmer}`,
        description: `Học nguyên âm phụ thuộc ${item.khmer} (${item.romanized})`,
        type: LESSON_TYPES.VOWEL,
        khmerText: item.khmer,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.pronunciation,
        difficulty: DIFFICULTY.BEGINNER,
        order: orderCounter++,
        category: 'Nguyên âm',
        isActive: true,
        // Listening question
        questions: [
          {
            question: `Đâu là cách đọc đúng của nguyên âm "${item.khmer}"?`,
            options: [item.pronunciation, 'srak o', 'srak e', 'srak a'],
            correctAnswer: 0,
            explanation: `Nguyên âm "${item.khmer}" được phát âm là "${item.pronunciation}".`
          }
        ]
      });
    }

    // 3. Seed Vocabulary
    for (const item of vocabularyList) {
      lessonsToInsert.push({
        title: `Từ vựng: ${item.khmer}`,
        description: `Học từ vựng phổ thông: ${item.khmer} nghĩa là ${item.meaning}`,
        type: LESSON_TYPES.VOCABULARY,
        khmerText: item.khmer,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.pronunciation,
        difficulty: DIFFICULTY.INTERMEDIATE,
        order: orderCounter++,
        category: item.category,
        isActive: true,
        examples: [
          {
            khmer: `ខ្ញុំចូលចិត្ត ${item.khmer}`,
            romanized: `khnhom chol chet ${item.romanized}`,
            meaning: `Tôi thích ${item.meaning.toLowerCase()}`
          }
        ],
        // Reading lines support
        readingLines: [
          {
            khmer: item.khmer,
            romanized: item.romanized,
            meaning: item.meaning
          },
          {
            khmer: `ខ្ញុំឃើញ ${item.khmer}`,
            romanized: `khnhom kheunh ${item.romanized}`,
            meaning: `Tôi nhìn thấy ${item.meaning.toLowerCase()}`
          }
        ],
        // Listening questions
        questions: [
          {
            question: `Nghĩa tiếng Việt của từ "${item.khmer}" (${item.romanized}) là gì?`,
            options: [item.meaning, 'Quả táo', 'Điện thoại', 'Bầu trời'],
            correctAnswer: 0,
            explanation: `Từ "${item.khmer}" trong tiếng Khmer mang ý nghĩa là "${item.meaning}".`
          }
        ]
      });
    }

    const insertedLessons = await Lesson.insertMany(lessonsToInsert);
    console.log(`🎉 Successfully seeded ${insertedLessons.length} new lessons!`);
    console.log(`- Consonants: ${consonantsList.length}`);
    console.log(`- Vowels: ${vowelsList.length}`);
    console.log(`- Vocabulary: ${vocabularyList.length}`);

    return insertedLessons;
  } catch (error) {
    console.error('❌ Error seeding lessons:', error.message);
    throw error;
  }
};

// If run directly
if (require.main === module) {
  mongoose.connect(process.env.MONGO_URI)
    .then(() => {
      console.log('🔌 Connected to MongoDB for seeding lessons.');
      return seedLessons();
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

module.exports = seedLessons;
