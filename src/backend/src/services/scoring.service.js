/**
 * ========================================
 * Pronunciation Scoring Engine
 * ========================================
 * 
 * Implements Jaro-Winkler Similarity from scratch
 * and calculates the final weighted pronunciation score.
 */

/**
 * Tính toán độ tương đồng Jaro giữa hai chuỗi s1 và s2
 * @param {string} s1 - Chuỗi thứ nhất
 * @param {string} s2 - Chuỗi thứ hai
 * @returns {number} - Giá trị tương đồng Jaro (0 đến 1)
 */
function jaroSimilarity(s1, s2) {
  const len1 = s1.length;
  const len2 = s2.length;

  if (len1 === 0 && len2 === 0) return 1.0;
  if (len1 === 0 || len2 === 0) return 0.0;

  // Phạm vi khớp tối đa (Match window bound)
  const matchBound = Math.max(0, Math.floor(Math.max(len1, len2) / 2) - 1);

  const s1Matches = new Array(len1).fill(false);
  const s2Matches = new Array(len2).fill(false);

  let matches = 0;

  // Tìm các ký tự khớp nhau trong phạm vi cửa sổ
  for (let i = 0; i < len1; i++) {
    const start = Math.max(0, i - matchBound);
    const end = Math.min(len2, i + matchBound + 1);

    for (let j = start; j < end; j++) {
      if (!s2Matches[j] && s1[i] === s2[j]) {
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }
  }

  if (matches === 0) return 0.0;

  // Tính số lượng hoán vị (Transpositions)
  let k = 0;
  let transpositions = 0;
  for (let i = 0; i < len1; i++) {
    if (s1Matches[i]) {
      while (!s2Matches[k]) {
        k++;
      }
      if (s1[i] !== s2[k]) {
        transpositions++;
      }
      k++;
    }
  }

  const t = transpositions / 2;

  // Công thức Jaro: (m/|s1| + m/|s2| + (m - t)/m) / 3
  return (matches / len1 + matches / len2 + (matches - t) / matches) / 3;
}

/**
 * Tính toán độ tương đồng Jaro-Winkler giữa hai chuỗi
 * @param {string} s1 - Chuỗi thứ nhất
 * @param {string} s2 - Chuỗi thứ hai
 * @param {number} p - Hệ số prefix scaling factor (mặc định 0.1, tối đa 0.25)
 * @returns {number} - Giá trị tương đồng Jaro-Winkler (0 đến 1)
 */
function jaroWinkler(s1, s2, p = 0.1) {
  // Đảm bảo p không vượt quá 0.25 để tránh giá trị tương đồng lớn hơn 1.0
  const prefixFactor = Math.min(Math.max(0, p), 0.25);
  const jaroSim = jaroSimilarity(s1, s2);

  // Tính độ dài tiền tố khớp tối đa 4 ký tự ở đầu hai chuỗi
  let l = 0;
  const maxPrefix = Math.min(4, Math.min(s1.length, s2.length));
  for (let i = 0; i < maxPrefix; i++) {
    if (s1[i] === s2[i]) {
      l++;
    } else {
      break;
    }
  }

  // Công thức Jaro-Winkler: sim_j + l * p * (1 - sim_j)
  const jaroWinklerSim = jaroSim + l * prefixFactor * (1 - jaroSim);
  return Math.min(1.0, Math.max(0.0, jaroWinklerSim));
}

// ═══════════════════════════════════════════════════════════════════════
// Number Normalization Helpers
// ═══════════════════════════════════════════════════════════════════════

/**
 * Mapping from Arabic digits / Khmer digits to Khmer number words.
 * Used when Google STT returns "2" instead of "ពីរ".
 */
const DIGIT_TO_KHMER_WORD = {
  '0': 'សូន្យ',
  '1': 'មួយ',
  '2': 'ពីរ',
  '3': 'បី',
  '4': 'បួន',
  '5': 'ប្រាំ',
  '6': 'ប្រាំមួយ',
  '7': 'ប្រាំពីរ',
  '8': 'ប្រាំបី',
  '9': 'ប្រាំបួន',
};

const KHMER_DIGIT_TO_WORD = {
  '០': 'សូន្យ',
  '១': 'មួយ',
  '២': 'ពីរ',
  '៣': 'បី',
  '៤': 'បួន',
  '៥': 'ប្រាំ',
  '៦': 'ប្រាំមួយ',
  '៧': 'ប្រាំពីរ',
  '៨': 'ប្រាំបី',
  '៩': 'ប្រាំបួន',
};

// Reverse lookup: Khmer word → set of digit forms that match it
const KHMER_WORD_TO_DIGITS = {};
for (const [digit, word] of Object.entries(DIGIT_TO_KHMER_WORD)) {
  if (!KHMER_WORD_TO_DIGITS[word]) KHMER_WORD_TO_DIGITS[word] = new Set();
  KHMER_WORD_TO_DIGITS[word].add(digit);
}
for (const [khDigit, word] of Object.entries(KHMER_DIGIT_TO_WORD)) {
  if (!KHMER_WORD_TO_DIGITS[word]) KHMER_WORD_TO_DIGITS[word] = new Set();
  KHMER_WORD_TO_DIGITS[word].add(khDigit);
}

/**
 * Convert a digit transcript (Arabic or Khmer digit) to the Khmer word.
 * @param {string} text
 * @returns {string} Khmer word if text is a digit, otherwise unchanged
 */
function normalizeDigitToKhmerWord(text) {
  const trimmed = text.trim();
  if (DIGIT_TO_KHMER_WORD[trimmed]) return DIGIT_TO_KHMER_WORD[trimmed];
  if (KHMER_DIGIT_TO_WORD[trimmed]) return KHMER_DIGIT_TO_WORD[trimmed];
  return text;
}

/**
 * Check if recognized text is a digit that matches the expected Khmer number word.
 * @param {string} expected - e.g. "ពីរ"
 * @param {string} recognized - e.g. "2" or "២"
 * @returns {boolean}
 */
function isDigitMatchForKhmerWord(expected, recognized) {
  const trimmedRecognized = recognized.trim();
  // Only match if recognized is actually a digit character
  const digitSet = KHMER_WORD_TO_DIGITS[expected];
  if (digitSet && digitSet.has(trimmedRecognized)) return true;
  // Check if recognized is an Arabic or Khmer digit that maps to expected
  if (DIGIT_TO_KHMER_WORD[trimmedRecognized] === expected) return true;
  if (KHMER_DIGIT_TO_WORD[trimmedRecognized] === expected) return true;
  return false;
}

/**
 * Đánh giá kết quả phát âm dựa trên chuỗi chuẩn và nhận dạng từ STT
 * @param {string} expectedText - Từ mục tiêu (đã normalize)
 * @param {string} recognizedText - Từ nhận dạng từ Google STT (đã normalize)
 * @param {number} confidence - Độ tin cậy từ Google STT (0 - 1)
 * @param {boolean} isSTTEmpty - Trạng thái rỗng của Google STT
 * @returns {object} - Kết quả chấm điểm Pronunciation Result
 */
function calculatePronunciationScore(expectedText, recognizedText, confidence, isSTTEmpty) {
  // 1. Trường hợp đặc biệt: Không nhận được giọng nói từ Google STT hoặc chuỗi rỗng
  if (isSTTEmpty === true || !recognizedText || recognizedText.trim() === "") {
    return {
      similarityPercentage: 0.0,
      finalScore: 0.0,
      isCorrect: false,
      scoringMethod: 'stt_empty'
    };
  }

  let cleanExpected = expectedText;
  let cleanRecognized = recognizedText;

  // ── Number handling ─────────────────────────────────────────────
  // Google STT for Khmer (km-KH) frequently returns Arabic digits ("2")
  // instead of the Khmer word ("ពីរ") when a user speaks a number.
  // Detect this and either give an exact match or normalize before Jaro-Winkler.
  if (isDigitMatchForKhmerWord(cleanExpected, cleanRecognized)) {
    const similarityPercentage = 100.0;
    const finalScoreRaw = (similarityPercentage * 0.7) + (confidence * 100 * 0.3);
    const finalScore = Math.round(finalScoreRaw * 10) / 10;
    return {
      similarityPercentage: 100.0,
      finalScore,
      isCorrect: finalScore >= 65.0,
      scoringMethod: 'digit_match'
    };
  }
  // Normalize digit transcripts to Khmer words for Jaro-Winkler comparison
  cleanRecognized = normalizeDigitToKhmerWord(cleanRecognized);

  // Loại bỏ ký tự carrier អ (U+17A2) của nguyên âm nếu chuỗi bắt đầu bằng អ và có độ dài >= 2.
  // Điều này đảm bảo rằng chúng ta chỉ so khớp phần âm tiết thực tế của nguyên âm (diacritic),
  // tránh việc các nguyên âm khác nhau (ví dụ: អឹ và អា) khớp nhau với điểm số cao (70%) 
  // chỉ vì chúng đều chia sẻ ký tự placeholder អ ở đầu.
  if (cleanExpected.startsWith('\u17A2') && cleanExpected.length >= 2) {
    cleanExpected = cleanExpected.slice(1);
  }
  if (cleanRecognized.startsWith('\u17A2') && cleanRecognized.length >= 2) {
    cleanRecognized = cleanRecognized.slice(1);
  }

  // 2. Trường hợp đặc biệt: Chuỗi khớp chính xác 100% sau khi chuẩn hóa
  if (cleanExpected === cleanRecognized) {
    const similarityPercentage = 100.0;
    // Công thức tính điểm cuối cùng: (tương đồng * 0.7) + (độ tin cậy * 100 * 0.3)
    const finalScoreRaw = (similarityPercentage * 0.7) + (confidence * 100 * 0.3);
    const finalScore = Math.round(finalScoreRaw * 10) / 10;
    const isCorrect = finalScore >= 65.0;

    return {
      similarityPercentage: 100.0,
      finalScore,
      isCorrect,
      scoringMethod: 'jaro_winkler'
    };
  }

  // 3. Tính toán độ tương đồng sử dụng Jaro-Winkler
  // THÔNG TIN KIẾN TRÚC:
  // Jaro-Winkler tốt hơn với các từ ngắn (tiếng Khmer đơn vị là các từ ngắn riêng lẻ).
  // Ít nhạy cảm hơn đối với sự khác biệt nhỏ ở đầu chuỗi (hoạt động tốt cho phiên âm gần đúng).
  // ĐẶC BIỆT LƯU Ý: Nếu targetWord là câu dài (> 5 từ), thuật toán Levenshtein Distance sẽ phù hợp
  // và tối ưu hơn so với Jaro-Winkler để đánh giá sự dịch chuyển cấu trúc từ trong câu.
  const jaroWinklerSim = jaroWinkler(cleanExpected, cleanRecognized, 0.1);

  // Áp dụng phạt theo tỷ lệ độ dài chuỗi (Length Penalty Factor)
  // để tránh việc các chuỗi rất ngắn (ví dụ: nguyên âm អា chỉ dài 2 ký tự)
  // khớp với các chuỗi rất dài chứa nó (ví dụ: "អាហាហាអាហា" dài 10 ký tự)
  // với điểm tương đồng Jaro-Winkler quá cao.
  const len1 = cleanExpected.length;
  const len2 = cleanRecognized.length;
  const lengthRatio = Math.min(len1, len2) / Math.max(len1, len2);
  const lengthPenalty = Math.sqrt(lengthRatio);

  const similarityPercentage = Math.round(jaroWinklerSim * lengthPenalty * 100 * 10) / 10;

  // 4. Áp dụng công thức trọng số 0.7 cho độ tương đồng từ và 0.3 cho độ tin cậy của Google STT
  // Lý do: Với tiếng Khmer ('km-KH'), độ tin cậy từ Google thường bị đánh giá thấp hơn giá trị thực.
  // Việc tăng trọng số confidence lên 0.3 giúp khuyến khích trẻ khi nói rõ ràng dù chuỗi không khớp hoàn toàn.
  const finalScoreRaw = (similarityPercentage * 0.7) + (confidence * 100 * 0.3);
  const finalScore = Math.round(finalScoreRaw * 10) / 10;

  // 5. Ngưỡng đạt (Pass Threshold) là >= 65 để bao dung hơn với trẻ em nói tiếng Khmer trên thiết bị di động
  const isCorrect = finalScore >= 65.0;

  return {
    similarityPercentage,
    finalScore,
    isCorrect,
    scoringMethod: 'jaro_winkler'
  };
}

module.exports = {
  jaroSimilarity,
  jaroWinkler,
  calculatePronunciationScore
};
