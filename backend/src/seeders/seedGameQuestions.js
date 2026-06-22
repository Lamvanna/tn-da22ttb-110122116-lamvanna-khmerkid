/**
 * ========================================
 * Game Question Seeder
 * ========================================
 * 
 * Seeds default questions for all 4 games:
 * 1. letter_catch (Bắt chữ Khmer) - 20 questions
 * 2. word_search (Giải cứu thú rừng) - 5 levels
 * 3. sentence_builder (Đảo quốc Ngữ pháp) - 5 levels
 * 4. math_garden (Khu vườn Toán học) - 20 levels
 */

require('dotenv').config();
const mongoose = require('mongoose');
const GameQuestion = require('../models/GameQuestion');

const letterCatchQuestions = [
  { gameKey: 'letter_catch', title: 'Bắt chữ: quạ', prompt: 'quạ', answer: 'កា', choices: ['ក', 'ា', 'ម', 'ី', 'ដ', 'ូ'], additionalData: { consonant: 'ក', vowel: 'ា' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: mẹ', prompt: 'mẹ', answer: 'មា', choices: ['ម', 'ា', 'ក', 'ី', 'ត', 'ូ'], additionalData: { consonant: 'ម', vowel: 'ា' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: ông', prompt: 'ông', answer: 'តា', choices: ['ត', 'ា', 'ប', 'ី', 'ស', 'ូ'], additionalData: { consonant: 'ត', vowel: 'ា' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: cha', prompt: 'cha', answer: 'បា', choices: ['ប', 'ា', 'ក', 'ី', 'ម', 'ូ'], additionalData: { consonant: 'ប', vowel: 'ា' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: xoay', prompt: 'xoay', answer: 'សា', choices: ['ស', 'ា', 'ត', 'ី', 'ร', 'ូ'], additionalData: { consonant: 'ស', vowel: 'ា' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: khó chịu', prompt: 'khó chịu', answer: 'កី', choices: ['ក', 'ី', 'ម', 'ា', 'ដ', 'ូ'], additionalData: { consonant: 'ក', vowel: 'ី' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: mì', prompt: 'mì', answer: 'មី', choices: ['ម', 'ី', 'ក', 'ា', 'រ', 'ូ'], additionalData: { consonant: 'ម', vowel: 'ី' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: đất', prompt: 'đất', answer: 'ដី', choices: ['ដ', 'ី', 'ត', 'ា', 'ប', 'ូ'], additionalData: { consonant: 'ដ', vowel: 'ី' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: con', prompt: 'con', answer: 'កូ', choices: ['ក', 'ូ', 'រ', 'ី', 'ន', 'ំ'], additionalData: { consonant: 'ក', vowel: 'ូ' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: hình', prompt: 'hình', answer: 'រូ', choices: ['រ', 'ូ', 'ក', 'ែ', 'ទ', 'ៅ'], additionalData: { consonant: 'រ', vowel: 'ូ' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: bánh', prompt: 'bánh', answer: 'នំ', choices: ['ន', 'ំ', 'ក', 'ែ', 'ទ', 'ៅ'], additionalData: { consonant: 'ន', vowel: 'ំ' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: sửa', prompt: 'sửa', answer: 'កែ', choices: ['ក', 'ែ', 'ទ', 'ៅ', 'ច', 'ា'], additionalData: { consonant: 'ក', vowel: 'ែ' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: đi', prompt: 'đi', answer: 'ទៅ', choices: ['ទ', 'ៅ', 'ច', 'ា', 'ព', 'ី'], additionalData: { consonant: 'ទ', vowel: 'ៅ' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: chiên', prompt: 'chiên', answer: 'ចា', choices: ['ច', 'ា', 'ព', 'ី', 'ល', 'ា'], additionalData: { consonant: 'ច', vowel: 'ា' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: từ', prompt: 'từ', answer: 'ពី', choices: ['ព', 'ី', 'ល', 'ា', 'ថ', 'ា'], additionalData: { consonant: 'ព', vowel: 'ី' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: tạm biệt', prompt: 'tạm biệt', answer: 'លា', choices: ['ល', 'ា', 'ថ', 'ា', 'យ', 'ូ'], additionalData: { consonant: 'ល', vowel: 'ា' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: nói', prompt: 'nói', answer: 'ថា', choices: ['ថ', 'ា', 'យ', 'ូ', 'ហ', 'ា'], additionalData: { consonant: 'ថ', vowel: 'ា' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: lâu', prompt: 'lâu', answer: 'យូ', choices: ['យ', 'ូ', 'ហ', 'ា', 'ឈ', 'ឺ'], additionalData: { consonant: 'យ', vowel: 'ូ' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: há', prompt: 'há', answer: 'ហា', choices: ['ហ', 'ា', 'ឈ', 'ឺ', 'ក', 'ា'], additionalData: { consonant: 'ហ', vowel: 'ា' } },
  { gameKey: 'letter_catch', title: 'Bắt chữ: đau/ốm', prompt: 'đau/ốm', answer: 'ឈឺ', choices: ['ឈ', 'ឺ', 'ក', 'ា', 'ម', 'ា'], additionalData: { consonant: 'ឈ', vowel: 'ឺ' } }
];

const wordSearchQuestions = [
  {
    gameKey: 'word_search',
    title: 'Giải cứu: CON VOI',
    prompt: 'CON VOI',
    answer: 'ដំរី',
    choices: [],
    additionalData: {
      romanized: 'dâm-rei',
      emoji: '🐘',
      objective: 'Tìm phụ âm ដ, nguyên âm ំ, phụ âm រ, nguyên âm ី',
      grid: [
        ['ក', 'ខ', 'គ', 'ឃ', 'ង'],
        ['ដ', 'ំ', 'រ', 'ី', 'ច'],
        ['ឆ', 'ជ', 'ឈ', 'ញ', 'ដ'],
        ['ឋ', 'ឌ', 'ឍ', 'ណ', 'ត'],
        ['ថ', 'ទ', 'ធ', 'ន', 'ប'],
        ['ផ', 'ព', 'ភ', 'ម', 'យ']
      ],
      path: [
        [1, 0],
        [1, 1],
        [1, 2],
        [1, 3]
      ]
    }
  },
  {
    gameKey: 'word_search',
    title: 'Giải cứu: CON HỔ',
    prompt: 'CON HỔ',
    answer: 'ខ្លា',
    choices: [],
    additionalData: {
      romanized: 'khla',
      emoji: '🐯',
      objective: 'Tìm phụ âm ខ, chân chữ ្ល, nguyên âm ា',
      grid: [
        ['%','ដ','ឋ','ឌ','ឍ'],
        ['ណ','ត','ថ','ទ','ធ'],
        ['ខ','្ល','ា','ន','ប'],
        ['ផ','ព','ភ','ម','យ'],
        ['ร','ល','វ','ស','ហ'],
        ['ឡ','អ','ក','ខ','គ']
      ],
      path: [
        [2, 0],
        [2, 1],
        [2, 2]
      ]
    }
  },
  {
    gameKey: 'word_search',
    title: 'Giải cứu: CON KHỈ',
    prompt: 'CON KHỈ',
    answer: 'ស្វា',
    choices: [],
    additionalData: {
      romanized: 'sva',
      emoji: '🐒',
      objective: 'Tìm phụ âm ស, chân chữ ្វ, nguyên âm ា',
      grid: [
        ['ឡ','អ','ក','ខ','គ'],
        ['ឃ','ង','ច','ឆ','ជ'],
        ['ឈ','ស','ញ','ដ','ឋ'],
        ['ឌ','្វ','ឍ','ណ','ត'],
        ['ថ','ា','ទ','ធ','ន'],
        ['ផ','ព','ភ','ម','យ']
      ],
      path: [
        [2, 1],
        [3, 1],
        [4, 1]
      ]
    }
  },
  {
    gameKey: 'word_search',
    title: 'Giải cứu: CON CÁ',
    prompt: 'CON CÁ',
    answer: 'ត្រី',
    choices: [],
    additionalData: {
      romanized: 'trei',
      emoji: '🐟',
      objective: 'Tìm phụ âm ត, chân chữ ្រ, nguyên âm ី',
      grid: [
        ['ត','ខ','គ','ឃ','ង'],
        ['្រ','ច','ឆ','ជ','ឈ'],
        ['ី','ញ','ដ','ឋ','ឌ'],
        ['ឍ','ណ','ត','ថ','ទ'],
        ['ធ','ន','ប','ផ','ព'],
        ['ឡ','អ','ក','ខ','គ']
      ],
      path: [
        [0, 0],
        [1, 0],
        [2, 0]
      ]
    }
  },
  {
    gameKey: 'word_search',
    title: 'Giải cứu: CON ONG',
    prompt: 'CON ONG',
    answer: 'ឃ្មុំ',
    choices: [],
    additionalData: {
      romanized: 'khmum',
      emoji: '🐝',
      objective: 'Tìm phụ âm ឃ, chân chữ ្ម, nguyên âm ុំ',
      grid: [
        ['ភ','ម','យ','ร','ល'],
        ['វ','ស','ហ','ឡ','អ'],
        ['ក','ខ','គ','ឃ','ង'],
        ['ច','ឆ','ជ','្ម','ញ'],
        ['ដ','ឋ','ឌ','ុំ','ឍ'],
        ['ត','ថ','ទ','ធ','ន']
      ],
      path: [
        [2, 3],
        [3, 3],
        [4, 3]
      ]
    }
  }
];

const sentenceBuilderQuestions = [
  {
    gameKey: 'sentence_builder',
    title: 'Sắp xếp: Tôi đi học',
    prompt: 'Tôi đi học',
    answer: 'ខ្ញុំ ទៅ សាលារៀន',
    choices: ['ខ្ញុំ', 'ទៅ', 'សាលារៀន'],
    additionalData: {
      wordMeanings: {
        'ខ្ញុំ': 'Tôi',
        'ទៅ': 'đi',
        'សាលារៀន': 'trường học'
      },
      wordTypes: ['subject', 'verb', 'object'],
      islandName: 'Đảo Ngọc Trai',
      emoji: '🏝️'
    }
  },
  {
    gameKey: 'sentence_builder',
    title: 'Sắp xếp: Mẹ mua trái cây',
    prompt: 'Mẹ mua trái cây',
    answer: 'ម៉ាក់ ទិញ ផ្លែឈើ',
    choices: ['ម៉ាក់', 'ទិញ', 'ផ្លែឈើ'],
    additionalData: {
      wordMeanings: {
        'ម៉ាក់': 'Mẹ',
        'ទិញ': 'mua',
        'ផ្លែឈើ': 'trái cây'
      },
      wordTypes: ['subject', 'verb', 'object'],
      islandName: 'Đảo Cọ Vàng',
      emoji: '🌴'
    }
  },
  {
    gameKey: 'sentence_builder',
    title: 'Sắp xếp: Em bé uống sữa',
    prompt: 'Em bé uống sữa',
    answer: 'កូនក្មេង ផឹក ទឹកដោះគោ',
    choices: ['កូនក្មេង', 'ផឹក', 'ទឹកដោះគោ'],
    additionalData: {
      wordMeanings: {
        'កូនក្មេង': 'Em bé',
        'ផឹក': 'uống',
        'ទឹកដោះគោ': 'sữa'
      },
      wordTypes: ['subject', 'verb', 'object'],
      islandName: 'Đảo Hải Âu',
      emoji: '🌊'
    }
  },
  {
    gameKey: 'sentence_builder',
    title: 'Sắp xếp: Tôi thích ăn cơm',
    prompt: 'Tôi thích ăn cơm',
    answer: 'ខ្ញុំ ចូលចិត្ត ញ៉ាំ បាយ',
    choices: ['ខ្ញុំ', 'ចូលចិត្ត', 'ញ៉ាំ', 'បាយ'],
    additionalData: {
      wordMeanings: {
        'ខ្ញុំ': 'Tôi',
        'ចូលចិត្ត': 'thích',
        'ញ៉ាំ': 'ăn',
        'បាយ': 'cơm'
      },
      wordTypes: ['subject', 'verb', 'verb', 'object'],
      islandName: 'Đảo San Hô',
      emoji: '🐚'
    }
  },
  {
    gameKey: 'sentence_builder',
    title: 'Sắp xếp: Chú voi ăn chuối',
    prompt: 'Chú voi ăn chuối',
    answer: 'ដំរី ស៊ី ចេក',
    choices: ['ដំរី', 'ស៊ី', 'ចេក'],
    additionalData: {
      wordMeanings: {
        'ដំរី': 'Chú voi',
        'ស៊ី': 'ăn (động vật)',
        'ចេក': 'chuối'
      },
      wordTypes: ['subject', 'verb', 'object'],
      islandName: 'Đảo Đá Cổ',
      emoji: '🗿'
    }
  }
];

const mathGardenQuestions = [
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm táo chín',
    prompt: 'Bé hãy đếm số quả táo đỏ chín trên cây nhé! 🍎',
    answer: '៥',
    choices: ['៣', '៤', '៥'],
    additionalData: {
      khmerProblem: '🍎 🍎 🍎 🍎 🍎',
      romanized: 'prăm',
      arabicMeaning: '5',
      visualEmojis: ['🍎', '🍎', '🍎', '🍎', '🍎'],
      gardenName: 'Vườn Táo Đỏ',
      bgGradient: ['#F57C00', '#FFB74D']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Một cộng hai',
    prompt: 'Bé hãy tính phép cộng sau bằng chữ số Khmer: ១ + ២ = ?',
    answer: '៣',
    choices: ['២', '៣', '៤'],
    additionalData: {
      khmerProblem: '១ + ២ = ?',
      romanized: 'bei',
      arabicMeaning: '3',
      visualEmojis: ['🦋', '➕', '🐝', '🐝'],
      gardenName: 'Đồi Bươm Bướm',
      bgGradient: ['#43A047', '#81C784']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm hoa hướng dương',
    prompt: 'Có bao nhiêu bông hoa hướng dương đang nở rực rỡ? 🌻',
    answer: '៧',
    choices: ['៦', '៧', '៨'],
    additionalData: {
      khmerProblem: '🌻 🌻 🌻 🌻 🌻 🌻 🌻',
      romanized: 'prăm-pi',
      arabicMeaning: '7',
      visualEmojis: ['🌻', '🌻', '🌻', '🌻', '🌻', '🌻', '🌻'],
      gardenName: 'Đồng Hướng Dương',
      bgGradient: ['#E65100', '#FFB74D']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Năm trừ hai',
    prompt: 'Bé tính giúp chú voi con: ៥ - ២ = ?',
    answer: '៣',
    choices: ['៣', '៤', '៥'],
    additionalData: {
      khmerProblem: '៥ - ២ = ?',
      romanized: 'bei',
      arabicMeaning: '3',
      visualEmojis: ['🍌', '🍌', '🍌', '🍌', '🍌', '➖', '🍌', '🍌'],
      gardenName: 'Rừng Chuối Chín',
      bgGradient: ['#2E7D32', '#4CAF50']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm nấm cỏ',
    prompt: 'Bé hãy đếm xem có bao nhiêu cây nấm nhỏ trong cỏ? 🍄',
    answer: '៩',
    choices: ['៧', '៨', '៩'],
    additionalData: {
      khmerProblem: '🍄 🍄 🍄 🍄 🍄 🍄 🍄 🍄 🍄',
      romanized: 'prăm-buon',
      arabicMeaning: '9',
      visualEmojis: ['🍄', '🍄', '🍄', '🍄', '🍄', '🍄', '🍄', '🍄', '🍄'],
      gardenName: 'Góc Nấm Mưa',
      bgGradient: ['#00796B', '#4DB6AC']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm quả cam',
    prompt: 'Bé hãy giúp đếm số quả cam ngọt ngào trên cành nhé! 🍊',
    answer: '៦',
    choices: ['៥', '៦', '៧'],
    additionalData: {
      khmerProblem: '🍊 🍊 🍊 🍊 🍊 🍊',
      romanized: 'prăm-muoy',
      arabicMeaning: '6',
      visualEmojis: ['🍊', '🍊', '🍊', '🍊', '🍊', '🍊'],
      gardenName: 'Vườn Cam Ngọt',
      bgGradient: ['#E65100', '#FFB74D']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm cà rốt',
    prompt: 'Chú thỏ trắng nhổ được bao nhiêu củ cà rốt giòn ngọt? 🥕',
    answer: '៤',
    choices: ['៣', '៤', '៥'],
    additionalData: {
      khmerProblem: '🥕 🥕 🥕 🥕',
      romanized: 'buon',
      arabicMeaning: '4',
      visualEmojis: ['🥕', '🥕', '🥕', '🥕'],
      gardenName: 'Góc Cà Rốt',
      bgGradient: ['#F57C00', '#FF9800']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm hoa sen',
    prompt: 'Bé hãy đếm xem có bao nhiêu bông hoa sen nở dưới ao? 🪷',
    answer: '៨',
    choices: ['៧', '៨', '៩'],
    additionalData: {
      khmerProblem: '🪷 🪷 🪷 🪷 🪷 🪷 🪷 🪷',
      romanized: 'prăm-bei',
      arabicMeaning: '8',
      visualEmojis: ['🪷', '🪷', '🪷', '🪷', '🪷', '🪷', '🪷', '🪷'],
      gardenName: 'Hồ Hoa Sen',
      bgGradient: ['#00ACC1', '#4DD0E1']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm dâu tây',
    prompt: 'Có bao nhiêu quả dâu tây đỏ mọng chín ngọt ngào? 🍓',
    answer: '១០',
    choices: ['៨', '៩', '១០'],
    additionalData: {
      khmerProblem: '🍓 🍓 🍓 🍓 🍓 🍓 🍓 🍓 🍓 🍓',
      romanized: 'dop',
      arabicMeaning: '10',
      visualEmojis: ['🍓', '🍓', '🍓', '🍓', '🍓', '🍓', '🍓', '🍓', '🍓', '🍓'],
      gardenName: 'Vườn Dâu Tây',
      bgGradient: ['#EF5350', '#E57373']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm cá vàng',
    prompt: 'Bé hãy đếm xem có bao nhiêu bạn cá vàng đang bơi lội vui vẻ? 🐟',
    answer: '៣',
    choices: ['២', '៣', '៤'],
    additionalData: {
      khmerProblem: '🐟 🐟 🐟',
      romanized: 'bei',
      arabicMeaning: '3',
      visualEmojis: ['🐟', '🐟', '🐟'],
      gardenName: 'Ao Cá Vàng',
      bgGradient: ['#29B6F6', '#81D4FA']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Ba cộng bốn',
    prompt: 'Bé hãy giúp bạn ong mật tính toán phép tính: ៣ + ៤ = ?',
    answer: '៧',
    choices: ['៦', '៧', '៨'],
    additionalData: {
      khmerProblem: '៣ + ៤ = ?',
      romanized: 'prăm-pi',
      arabicMeaning: '7',
      visualEmojis: ['🌹', '🌹', '🌹', '➕', '🌹', '🌹', '🌹', '🌹'],
      gardenName: 'Đồi Hoa Hồng',
      bgGradient: ['#AB47BC', '#CE93D8']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Sáu trừ ba',
    prompt: 'Bé giúp chú chim nhỏ hái dưa hấu: ៦ - ៣ = ?',
    answer: '៣',
    choices: ['២', '៣', '៤'],
    additionalData: {
      khmerProblem: '៦ - ៣ = ?',
      romanized: 'bei',
      arabicMeaning: '3',
      visualEmojis: ['🍉', '🍉', '🍉', '🍉', '🍉', '🍉', '➖', '🍉', '🍉', '🍉'],
      gardenName: 'Vườn Dưa Hấu',
      bgGradient: ['#4CAF50', '#81C784']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Bốn cộng năm',
    prompt: 'Bé hãy tính kết quả phép tính đố vui của chú sóc con: ៤ + ៥ = ?',
    answer: '៩',
    choices: ['៨', '៩', '១០'],
    additionalData: {
      khmerProblem: '៤ + ៥ = ?',
      romanized: 'prăm-buon',
      arabicMeaning: '9',
      visualEmojis: ['🌰', '🌰', '🌰', '🌰', '➕', '🌰', '🌰', '🌰', '🌰', '🌰'],
      gardenName: 'Khu Vườn Bí Ngô',
      bgGradient: ['#FF9800', '#FFB74D']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Tám trừ bốn',
    prompt: 'Bé hãy tính kết quả giúp thỏ con: ៨ - ៤ = ?',
    answer: '៤',
    choices: ['៣', '៤', '៥'],
    additionalData: {
      khmerProblem: '៨ - ៤ = ?',
      romanized: 'buon',
      arabicMeaning: '4',
      visualEmojis: ['🍇', '🍇', '🍇', '🍇', '🍇', '🍇', '🍇', '🍇', '➖', '🍇', '🍇', '🍇', '🍇'],
      gardenName: 'Vườn Nho Tím',
      bgGradient: ['#5C6BC0', '#9FA8DA']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm cherry',
    prompt: 'Bé hãy đếm xem có bao nhiêu quả cherry mọng đỏ trên cành? 🍒',
    answer: '២',
    choices: ['១', '២', '៣'],
    additionalData: {
      khmerProblem: '🍒 🍒',
      romanized: 'pi',
      arabicMeaning: '2',
      visualEmojis: ['🍒', '🍒'],
      gardenName: 'Vườn Cherry',
      bgGradient: ['#EF5350', '#FF8A80']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Hai cộng sáu',
    prompt: 'Bé giúp gấu con làm phép tính sau: ២ + ៦ = ?',
    answer: '៨',
    choices: ['៧', '៨', '៩'],
    additionalData: {
      khmerProblem: '២ + ៦ = ?',
      romanized: 'prăm-bei',
      arabicMeaning: '8',
      visualEmojis: ['🐝', '🐝', '➕', '🐝', '🐝', '🐝', '🐝', '🐝', '🐝'],
      gardenName: 'Khu Vườn Ong Mật',
      bgGradient: ['#FFC107', '#FFE082']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Chín trừ năm',
    prompt: 'Bé hãy giải phép tính đố của khỉ con nhé: ៩ - ៥ = ?',
    answer: '៤',
    choices: ['៣', '៤', '៥'],
    additionalData: {
      khmerProblem: '៩ - ៥ = ?',
      romanized: 'buon',
      arabicMeaning: '4',
      visualEmojis: ['🍍', '🍍', '🍍', '🍍', '🍍', '🍍', '🍍', '🍍', '🍍', '➖', '🍍', '🍍', '🍍', '🍍', '🍍'],
      gardenName: 'Vườn Dứa Thơm',
      bgGradient: ['#009688', '#80CBC4']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Đếm trứng',
    prompt: 'Đố bé biết trong ổ của gà mái vàng có bao nhiêu quả trứng? 🥚',
    answer: '១',
    choices: ['០', '១', '២'],
    additionalData: {
      khmerProblem: '🥚',
      romanized: 'muoy',
      arabicMeaning: '1',
      visualEmojis: ['🥚'],
      gardenName: 'Đồi Trứng Phục Sinh',
      bgGradient: ['#FFCC80', '#FFE0B2']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Năm cộng năm',
    prompt: 'Bé hãy giúp chú ếch xanh tính phép cộng sau: ៥ + ៥ = ?',
    answer: '១០',
    choices: ['៩', '១០', '១១'],
    additionalData: {
      khmerProblem: '៥ + ៥ = ?',
      romanized: 'dop',
      arabicMeaning: '10',
      visualEmojis: ['🐸', '🐸', '🐸', '🐸', '🐸', '➕', '🐸', '🐸', '🐸', '🐸', '🐸'],
      gardenName: 'Đầm Lầy Ếch Xanh',
      bgGradient: ['#2E7D32', '#81C784']
    }
  },
  {
    gameKey: 'math_garden',
    title: 'Toán vườn: Bảy trừ ba',
    prompt: 'Phép tính cuối cùng đố bé: ៧ - ៣ = ?',
    answer: '៤',
    choices: ['៣', '៤', '៥'],
    additionalData: {
      khmerProblem: '៧ - ៣ = ?',
      romanized: 'buon',
      arabicMeaning: '4',
      visualEmojis: ['🍅', '🍅', '🍅', '🍅', '🍅', '🍅', '🍅', '➖', '🍅', '🍅', '🍅'],
      gardenName: 'Khu Vườn Cà Chua',
      bgGradient: ['#EF5350', '#E57373']
    }
  }
];

const seedGameQuestions = async () => {
  try {
    console.log('⏳ Seeding Game Questions into Database...');
    const deleteResult = await GameQuestion.deleteMany({});
    console.log(`🧹 Cleared ${deleteResult.deletedCount} old game questions.`);

    const questionsToInsert = [
      ...letterCatchQuestions,
      ...wordSearchQuestions,
      ...sentenceBuilderQuestions,
      ...mathGardenQuestions
    ];

    const inserted = await GameQuestion.insertMany(questionsToInsert);
    console.log(`🎉 Successfully seeded ${inserted.length} game questions!`);
    console.log(`- Bắt chữ Khmer (letter_catch): ${letterCatchQuestions.length}`);
    console.log(`- Giải cứu thú rừng (word_search): ${wordSearchQuestions.length}`);
    console.log(`- Đảo quốc Ngữ pháp (sentence_builder): ${sentenceBuilderQuestions.length}`);
    console.log(`- Khu vườn Toán học (math_garden): ${mathGardenQuestions.length}`);
    return inserted;
  } catch (error) {
    console.error('❌ Error seeding game questions:', error.message);
    throw error;
  }
};

// If run directly
if (require.main === module) {
  mongoose.connect(process.env.MONGO_URI)
    .then(() => {
      console.log('🔌 Connected to MongoDB for seeding game questions.');
      return seedGameQuestions();
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

module.exports = seedGameQuestions;
