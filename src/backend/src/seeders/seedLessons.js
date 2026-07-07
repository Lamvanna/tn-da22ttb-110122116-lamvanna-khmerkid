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

const spellingList = [
  { khmer: 'កា', romanized: 'ka', meaning: 'Chữ Ka ghép vần A', pronunciation: 'ka', category: 'Ghép vần phụ âm - nguyên âm' },
  { khmer: 'ខិ', romanized: 'khi', meaning: 'Chữ Kha ghép vần I', pronunciation: 'khi', category: 'Ghép vần phụ âm - nguyên âm' },
  { khmer: 'គី', romanized: 'kii', meaning: 'Chữ Ko ghép vần Ii', pronunciation: 'kii', category: 'Ghép vần phụ âm - nguyên âm' },
  { khmer: 'ឃុ', romanized: 'khu', meaning: 'Chữ Kho ghép vần U', pronunciation: 'khu', category: 'Ghép vần phụ âm - nguyên âm' },
  { khmer: 'ងោ', romanized: 'ngao', meaning: 'Chữ Ngo ghép vần Ao', pronunciation: 'ngao', category: 'Ghép vần phụ âm - nguyên âm' },
];

const closedSyllableList = [
  { khmer: 'កក', romanized: 'kak', meaning: 'Đá lạnh / Đông đặc', pronunciation: 'kak', category: 'Ghép vần phụ âm - phụ âm (vần đóng)' },
  { khmer: 'បក', romanized: 'bok', meaning: 'Bóc vỏ', pronunciation: 'bok', category: 'Ghép vần phụ âm - phụ âm (vần đóng)' },
  { khmer: 'ដេក', romanized: 'dek', meaning: 'Ngủ', pronunciation: 'dek', category: 'Ghép vần phụ âm - phụ âm (vần đóng)' },
  { khmer: 'ធំ', romanized: 'thom', meaning: 'To lớn', pronunciation: 'thom', category: 'Ghép vần phụ âm - phụ âm (vần đóng)' },
];

const coengList = [
  { khmer: 'ខ្លា', romanized: 'khla', meaning: 'Con hổ', pronunciation: 'khla', category: 'Ghép vần phụ âm có chân (coeng)' },
  { khmer: 'ក្អែក', romanized: 'k-qek', meaning: 'Con quạ', pronunciation: 'k-qek', category: 'Ghép vần phụ âm có chân (coeng)' },
  { khmer: 'ឆ្កែ', romanized: 'chgai', meaning: 'Con chó', pronunciation: 'chgai', category: 'Ghép vần phụ âm có chân (coeng)' },
  { khmer: 'ថ្ម', romanized: 'th-mor', meaning: 'Đá (hòn đá)', pronunciation: 'th-mor', category: 'Ghép vần phụ âm có chân (coeng)' },
];

const diacriticalSpellingList = [
  { khmer: 'ម៉ា', romanized: 'ma', meaning: 'Mẹ (cách gọi thân mật)', pronunciation: 'ma', category: 'Ghép vần có dấu' },
  { khmer: 'ប៉ា', romanized: 'pa', meaning: 'Ba / Bố', pronunciation: 'pa', category: 'Ghép vần có dấu' },
  { khmer: 'ស៊ី', romanized: 'see', meaning: 'Ăn (dùng cho động vật hoặc thân mật)', pronunciation: 'see', category: 'Ghép vần có dấu' },
  { khmer: 'ហ៊ី', romanized: 'hee', meaning: 'Hát kịch / Tuồng', pronunciation: 'hee', category: 'Ghép vần có dấu' },
  { khmer: 'កក់', romanized: 'kok', meaning: 'Gội đầu / Đặt chỗ', pronunciation: 'kok', category: 'Ghép vần có dấu' },
];

const diacriticalList = [
  { character: '់', name: 'បន្តក់', romanized: 'Bantoc', description: 'Dấu ngắn - rút gọn nguyên âm', example: 'កក់', meaning: 'gội', category: 'Dấu Khmer' },
  { character: 'ំ', name: 'និគ្គហិត', romanized: 'Nikahit', description: 'Dấu âm mũi - thêm âm m', example: 'កំ', meaning: 'nắm', category: 'Dấu Khmer' },
  { character: 'ះ', name: 'រះមុក', romanized: 'Reahmuk', description: 'Dấu hơi thở - thêm âm h', example: 'សះ', meaning: 'lành', category: 'Dấu Khmer' },
  { character: 'ៈ', name: 'យុគលពិន្ទុ', romanized: 'Yukolpintu', description: 'Dấu hai chấm - ngắn hóa nguyên âm', example: 'នៈ', meaning: 'ấy', category: 'Dấu Khmer' },
  { character: '៉', name: 'មូសិកទន្ត', romanized: 'Musekadoan', description: 'Chuyển phụ âm hàng ô sang hàng o', example: 'ម៉ា', meaning: 'mẹ', category: 'Dấu Khmer' },
  { character: '៊', name: 'ត្រីសព្ទ', romanized: 'Treysap', description: 'Chuyển phụ âm hàng o sang hàng ô', example: 'ស៊ី', meaning: 'ăn', category: 'Dấu Khmer' },
  { character: '្', name: 'ជើង', romanized: 'Cheung', description: 'Phụ âm dưới - ghép phụ âm kép', example: 'ស្រា', meaning: 'rượu', category: 'Dấu Khmer' },
  { character: 'ៗ', name: 'លេខទោ', romanized: 'Lekto', description: 'Dấu lặp từ - lặp lại từ trước', example: 'ធំៗ', meaning: 'lớn lớn', category: 'Dấu Khmer' },
  { character: '។', name: 'ខ័ណ្ឌ', romanized: 'Khan', description: 'Dấu chấm câu - kết thúc câu', example: 'ខ្ញុំទៅ។', meaning: 'Tôi đi.', category: 'Dấu Khmer' },
  { character: '៎', name: 'កាកបាត', romanized: 'Kakabat', description: 'Dấu nhấn mạnh cảm xúc', example: 'អត់៎', meaning: 'không đâu!', category: 'Dấu Khmer' },
  { character: '៌', name: 'របាត', romanized: 'Robat', description: 'Dấu r viết trên - thay thế រ', example: 'ធម៌', meaning: 'dharma', category: 'Dấu Khmer' },
  { character: '័', name: 'សំយោគសញ្ញា', romanized: 'Samyok Sannya', description: 'Dấu thay đổi nguyên âm mặc định', example: 'ខ័ន', meaning: 'chặn', category: 'Dấu Khmer' },
];

const readingList = [
  {
    title: 'Bài 1: Phụ âm cơ bản',
    description: 'Đọc phụ âm ក - ខ',
    khmerText: '📖',
    category: '#4CAF50',
    examples: [
      { khmer: 'ក   ខ' },
      { khmer: 'ា  េ  ែ' },
      { khmer: 'កា   ការ   កកេរ' },
      { khmer: 'ខ   ខែ' }
    ]
  },
  {
    title: 'Bài 2: Từ đơn giản',
    description: 'Đọc từ 1-2 âm tiết',
    khmerText: '📗',
    category: '#2196F3',
    examples: [
      { khmer: 'កា' },
      { khmer: 'គោ' },
      { khmer: 'ឆ្មា' },
      { khmer: 'ឆ្កែ' },
      { khmer: 'ត្រី' }
    ]
  },
  {
    title: 'Bài 3: Câu ngắn',
    description: 'Đọc câu đơn giản',
    khmerText: '📘',
    category: '#E91E63',
    examples: [
      { khmer: 'ម៉ែ ស្រឡាញ់ ខ្ញុំ' },
      { khmer: 'ខ្ញុំ ទៅ សាលា' },
      { khmer: 'ប៉ា ធ្វើ ការ' }
    ]
  },
  {
    title: 'Bài 4: Số đếm',
    description: 'Đọc số từ 1-10',
    khmerText: '📙',
    category: '#FFFF98',
    examples: [
      { khmer: '១ ២ ៣ ៤ ៥' },
      { khmer: '៦ ៧ ៨ ៩ ១០' }
    ]
  },
  {
    title: 'Bài 5: Đoạn văn',
    description: 'Đọc đoạn văn ngắn',
    khmerText: '📕',
    category: '#7E57C2',
    examples: [
      { khmer: 'ខ្ញុំ ឈ្មោះ សុខា។' },
      { khmer: 'ខ្ញុំ រៀន នៅ សាលា។' },
      { khmer: 'ខ្ញុំ ស្រឡាញ់ គ្រូ។' },
      { khmer: 'ខ្ញុំ ស្រឡាញ់ ម៉ែ ប៉ា។' }
    ]
  }
];

const writingList = [
  { character: 'ឆ្មា', romanized: 'chma', meaning: 'Con mèo dễ thương', category: 'topic_1' },
  { character: 'ឆ្កែ', romanized: 'chkae', meaning: 'Con chó trung thành', category: 'topic_2' },
  { character: 'គោ', romanized: 'ko', meaning: 'Con bò kéo xe', category: 'topic_3' },
  { character: 'សេះ', romanized: 'seh', meaning: 'Con ngựa chạy nhanh', category: 'topic_4' },
  { character: 'មាន់', romanized: 'moan', meaning: 'Con gà gáy sáng', category: 'topic_5' },
  { character: 'ត្រី', romanized: 'trey', meaning: 'Con cá bơi dưới nước', category: 'topic_6' },
  { character: 'ដំរី', romanized: 'damrei', meaning: 'Con voi to lớn', category: 'topic_7' },
  { character: 'ប៉ា', romanized: 'pa', meaning: 'Bố yêu thương bé', category: 'topic_8' },
  { character: 'ម៉ែ', romanized: 'mae', meaning: 'Mẹ hiền chăm sóc bé', category: 'topic_9' },
  { character: 'តា', romanized: 'ta', meaning: 'Ông kể chuyện hay', category: 'topic_10' },
  { character: 'យាយ', romanized: 'yeay', meaning: 'Bà ru bé ngủ', category: 'topic_11' },
  { character: 'បង', romanized: 'bong', meaning: 'Anh chị nhường nhịn bé', category: 'topic_12' },
  { character: 'ប្អូន', romanized: 'paoun', meaning: 'Em bé đáng yêu', category: 'topic_13' },
  { character: 'ចេក', romanized: 'chek', meaning: 'Chuối chín vàng ngọt', category: 'topic_14' },
  { character: 'ដូង', romanized: 'doung', meaning: 'Nước dừa thơm mát', category: 'topic_15' },
  { character: 'ស្វាយ', romanized: 'svay', meaning: 'Xoài chín ngọt lịm', category: 'topic_16' },
  { character: 'សាលា', romanized: 'sala', meaning: 'Trường học mến yêu', category: 'topic_17' },
  { character: 'គ្រូ', romanized: 'kru', meaning: 'Cô giáo dạy học', category: 'topic_18' },
  { character: 'សៀវភៅ', romanized: 'sievphov', meaning: 'Sách mở ra tri thức', category: 'topic_19' },
  { character: 'ដៃ', romanized: 'dai', meaning: 'Bàn tay bé nhỏ', category: 'topic_20' }
];

const sentenceList = [
  { khmer: 'ខ្ញុំរៀនភាសាខ្មែរ', romanized: 'khnhom rien pheasa khmer', meaning: 'Tôi học tiếng Khmer', pronunciation: 'khnhom rien pheasa khmer', category: 'Giao tiếp cơ bản' },
  { khmer: 'សួស្តីឆ្នាំថ្មី', romanized: 'soustey chnam tmey', meaning: 'Chúc mừng năm mới', pronunciation: 'soustey chnam tmey', category: 'Giao tiếp cơ bản' },
  { khmer: 'ខ្ញុំស្រឡាញ់អ្នក', romanized: 'khnhom srolanh anak', meaning: 'Tôi yêu bạn', pronunciation: 'khnhom srolanh anak', category: 'Giao tiếp cơ bản' },
];

const numberList = [
  { khmer: '១', romanized: 'moi', meaning: 'Số 1', pronunciation: 'moi', category: 'Chữ số' },
  { khmer: '២', romanized: 'pi', meaning: 'Số 2', pronunciation: 'pi', category: 'Chữ số' },
  { khmer: '៣', romanized: 'bei', meaning: 'Số 3', pronunciation: 'bei', category: 'Chữ số' },
  { khmer: '៤', romanized: 'buon', meaning: 'Số 4', pronunciation: 'buon', category: 'Chữ số' },
  { khmer: '៥', romanized: 'pram', meaning: 'Số 5', pronunciation: 'pram', category: 'Chữ số' },
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

    // 4. Seed Spelling (Ghép vần)
    for (const item of spellingList) {
      lessonsToInsert.push({
        title: `Ghép vần: ${item.khmer}`,
        description: `Học cách ghép vần từ ${item.khmer} (${item.romanized})`,
        type: LESSON_TYPES.SPELLING,
        khmerText: item.khmer,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.pronunciation,
        difficulty: DIFFICULTY.BEGINNER,
        order: orderCounter++,
        category: item.category,
        isActive: true,
        questions: [
          {
            question: `Từ ghép vần "${item.khmer}" phát âm là gì?`,
            options: [item.pronunciation, 'ko', 'khe', 'nhu'],
            correctAnswer: 0,
            explanation: `Từ ghép vần "${item.khmer}" phát âm chính xác là "${item.pronunciation}".`
          }
        ]
      });
    }

    // 5. Seed Closed Syllable (Vần đóng)
    for (const item of closedSyllableList) {
      lessonsToInsert.push({
        title: `Vần đóng: ${item.khmer}`,
        description: `Học ghép vần đóng có phụ âm cuối: ${item.khmer}`,
        type: LESSON_TYPES.CLOSED_SYLLABLE,
        khmerText: item.khmer,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.pronunciation,
        difficulty: DIFFICULTY.INTERMEDIATE,
        order: orderCounter++,
        category: item.category,
        isActive: true,
        questions: [
          {
            question: `Phát âm đúng của từ vần đóng "${item.khmer}" là gì?`,
            options: [item.pronunciation, 'ka', 'ba', 'tha'],
            correctAnswer: 0,
            explanation: `Từ vần đóng "${item.khmer}" được phát âm là "${item.pronunciation}".`
          }
        ]
      });
    }

    // 5.5. Seed Diacritical Spelling (Ghép vần có dấu)
    for (const item of diacriticalSpellingList) {
      lessonsToInsert.push({
        title: `Ghép vần có dấu: ${item.khmer}`,
        description: `Học cách ghép vần có dấu từ ${item.khmer} (${item.romanized})`,
        type: LESSON_TYPES.SPELLING,
        khmerText: item.khmer,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.pronunciation,
        difficulty: DIFFICULTY.INTERMEDIATE,
        order: orderCounter++,
        category: item.category,
        isActive: true,
        questions: [
          {
            question: `Phát âm đúng của từ ghép vần có dấu "${item.khmer}" là gì?`,
            options: [item.pronunciation, 'ko', 'me', 'pa'],
            correctAnswer: 0,
            explanation: `Từ ghép vần có dấu "${item.khmer}" phát âm chính xác là "${item.pronunciation}".`
          }
        ]
      });
    }

    // 5.6. Seed Diacritical (Dấu Khmer)
    for (const item of diacriticalList) {
      lessonsToInsert.push({
        title: `Dấu Khmer: ${item.name}`,
        description: item.description,
        type: LESSON_TYPES.DIACRITICAL,
        khmerText: item.example,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.romanized,
        difficulty: DIFFICULTY.INTERMEDIATE,
        order: orderCounter++,
        category: item.category,
        isActive: true,
        questions: [
          {
            question: `Dấu "${item.character}" (${item.name}) có chức năng gì?`,
            options: [item.description, 'Dấu chấm câu', 'Dấu lặp từ', 'Dấu ngắn'],
            correctAnswer: 0,
            explanation: `Dấu "${item.character}" (${item.name}) có chức năng: ${item.description}.`
          }
        ]
      });
    }

    // 6. Seed Coeng (Chữ ghép / chân chữ)
    for (const item of coengList) {
      lessonsToInsert.push({
        title: `Chữ ghép: ${item.khmer}`,
        description: `Học phụ âm chồng có chân chữ (coeng): ${item.khmer}`,
        type: LESSON_TYPES.COENG,
        khmerText: item.khmer,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.pronunciation,
        difficulty: DIFFICULTY.INTERMEDIATE,
        order: orderCounter++,
        category: item.category,
        isActive: true,
        questions: [
          {
            question: `Cách phát âm của chữ ghép "${item.khmer}" là gì?`,
            options: [item.pronunciation, 'ka', 'cho', 'nho'],
            correctAnswer: 0,
            explanation: `Chữ ghép "${item.khmer}" được phát âm chính xác là "${item.pronunciation}".`
          }
        ]
      });
    }

    // 7. Seed Sentence (Câu)
    for (const item of sentenceList) {
      lessonsToInsert.push({
        title: `Câu: ${item.khmer}`,
        description: `Học mẫu câu giao tiếp: ${item.khmer}`,
        type: LESSON_TYPES.SENTENCE,
        khmerText: item.khmer,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.pronunciation,
        difficulty: DIFFICULTY.ADVANCED,
        order: orderCounter++,
        category: item.category,
        isActive: true,
        questions: [
          {
            question: `Nghĩa tiếng Việt của câu "${item.khmer}" là gì?`,
            options: [item.meaning, 'Hôm nay trời đẹp', 'Tôi muốn ăn cơm', 'Bạn tên là gì'],
            correctAnswer: 0,
            explanation: `Câu "${item.khmer}" mang ý nghĩa là "${item.meaning}".`
          }
        ]
      });
    }

    // 8. Seed Number (Số)
    for (const item of numberList) {
      lessonsToInsert.push({
        title: `Chữ số: ${item.khmer}`,
        description: `Học đếm số: ${item.khmer} (${item.meaning})`,
        type: LESSON_TYPES.NUMBER,
        khmerText: item.khmer,
        romanized: item.romanized,
        meaning: item.meaning,
        pronunciation: item.pronunciation,
        difficulty: DIFFICULTY.BEGINNER,
        order: orderCounter++,
        category: item.category,
        isActive: true,
        questions: [
          {
            question: `Chữ số "${item.khmer}" biểu diễn cho số mấy?`,
            options: [item.meaning, 'Số 6', 'Số 8', 'Số 9'],
            correctAnswer: 0,
            explanation: `Chữ số "${item.khmer}" biểu diễn cho "${item.meaning}".`
          }
        ]
      });
    }

    // 9. Seed Reading (Tập đọc)
    for (const item of readingList) {
      lessonsToInsert.push({
        title: item.title,
        description: item.description,
        type: LESSON_TYPES.READING,
        khmerText: item.khmerText,
        romanized: item.title,
        meaning: item.description,
        difficulty: DIFFICULTY.BEGINNER,
        order: orderCounter++,
        category: item.category,
        examples: item.examples,
        isActive: true,
      });
    }

    // 10. Seed Writing (Luyện viết)
    for (const item of writingList) {
      lessonsToInsert.push({
        title: `Luyện viết: ${item.character}`,
        description: item.meaning,
        type: LESSON_TYPES.WRITING,
        khmerText: item.character,
        romanized: item.romanized,
        meaning: item.meaning,
        difficulty: DIFFICULTY.BEGINNER,
        order: orderCounter++,
        category: item.category,
        isActive: true,
      });
    }

    const insertedLessons = await Lesson.insertMany(lessonsToInsert);
    console.log(`🎉 Successfully seeded ${insertedLessons.length} new lessons!`);
    console.log(`- Consonants: ${consonantsList.length}`);
    console.log(`- Vowels: ${vowelsList.length}`);
    console.log(`- Vocabulary: ${vocabularyList.length}`);
    console.log(`- Spelling (Ghép vần): ${spellingList.length}`);
    console.log(`- Diacritical Spelling (Ghép vần có dấu): ${diacriticalSpellingList.length}`);
    console.log(`- Diacritical (Dấu Khmer): ${diacriticalList.length}`);
    console.log(`- Closed Syllables (Vần đóng): ${closedSyllableList.length}`);
    console.log(`- Coeng (Chữ ghép): ${coengList.length}`);
    console.log(`- Sentences: ${sentenceList.length}`);
    console.log(`- Numbers: ${numberList.length}`);
    console.log(`- Reading (Tập đọc): ${readingList.length}`);
    console.log(`- Writing (Luyện viết): ${writingList.length}`);

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
