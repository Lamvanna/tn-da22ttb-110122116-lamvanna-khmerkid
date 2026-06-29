/**
 * ========================================
 * Jest Unit Tests - scoring.service
 * ========================================
 */

const {
  jaroSimilarity,
  jaroWinkler,
  calculatePronunciationScore
} = require('../src/services/scoring.service');

describe('Pronunciation Scoring Service Tests', () => {
  // Test case helper cho Jaro-Winkler
  describe('Jaro-Winkler Implementation', () => {
    test('exact match returns 1.0', () => {
      expect(jaroWinkler('ខ្មែរ', 'ខ្មែរ')).toBe(1.0);
    });

    test('completely different strings return 0.0', () => {
      // s1 và s2 không có ký tự chung nào
      expect(jaroWinkler('ក', 'ខ')).toBe(0.0);
    });

    test('partially matching strings return correct values', () => {
      const sim = jaroWinkler('សួស្តី', 'សួស្ដី'); // DA vs NNA subscript
      expect(sim).toBeGreaterThan(0.5);
      expect(sim).toBeLessThan(1.0);
    });
  });

  describe('calculatePronunciationScore', () => {
    // Case 1: Perfect Match
    test('Perfect Match: returns 100% similarity and high final score', () => {
      const expected = 'សួស្តី';
      const recognized = 'សួស្តី';
      const confidence = 0.8;
      
      const result = calculatePronunciationScore(expected, recognized, confidence, false);
      
      expect(result.similarityPercentage).toBe(100.0);
      // finalScore = (100 * 0.7) + (0.8 * 100 * 0.3) = 70 + 24 = 94
      expect(result.finalScore).toBe(94.0);
      expect(result.isCorrect).toBe(true);
      expect(result.scoringMethod).toBe('jaro_winkler');
    });

    // Case 2: STT Empty
    test('STT Empty: returns 0 score and stt_empty method', () => {
      const expected = 'ខ្មែរ';
      const recognized = '';
      const confidence = 0.0;
      
      const result = calculatePronunciationScore(expected, recognized, confidence, true);
      
      expect(result.similarityPercentage).toBe(0.0);
      expect(result.finalScore).toBe(0.0);
      expect(result.isCorrect).toBe(false);
      expect(result.scoringMethod).toBe('stt_empty');
    });

    // Case 3: Low Confidence (Underestimate check)
    test('Low Confidence: check if confidence weighted correctly', () => {
      const expected = 'ខ្មែរ';
      const recognized = 'ខ្មែរ';
      const confidence = 0.3; // Low confidence
      
      const result = calculatePronunciationScore(expected, recognized, confidence, false);
      
      expect(result.similarityPercentage).toBe(100.0);
      // finalScore = (100 * 0.7) + (0.3 * 100 * 0.3) = 70 + 9 = 79
      expect(result.finalScore).toBe(79.0);
      expect(result.isCorrect).toBe(true); // >= 65 is pass
    });

    // Case 4: Near Match (High similarity, passes threshold)
    test('Near Match: returns high similarity and passes pass threshold (65)', () => {
      const expected = 'សួស្តី';
      // Phát âm gần đúng, Google STT nhận dạng ra từ có chút sai lệch ở subscript
      const recognized = 'សួស្ដី'; 
      const confidence = 0.7;
      
      const result = calculatePronunciationScore(expected, recognized, confidence, false);
      
      expect(result.similarityPercentage).toBeGreaterThan(80.0);
      expect(result.finalScore).toBeGreaterThanOrEqual(65.0);
      expect(result.isCorrect).toBe(true);
    });

    // Case 5: Total Mismatch (Low similarity, fails threshold)
    test('Total Mismatch: returns low similarity and fails pass threshold', () => {
      const expected = 'ខ្មែរ';
      const recognized = 'សួស្តី';
      const confidence = 0.5;
      
      const result = calculatePronunciationScore(expected, recognized, confidence, false);
      
      expect(result.similarityPercentage).toBeLessThan(50.0);
      expect(result.finalScore).toBeLessThan(65.0);
      expect(result.isCorrect).toBe(false);
    });

    // Case 6: Vowel-to-Vowel Mismatch (e.g., Srak Ue vs Srak Aa, should not match despite sharing carrier អ)
    test('Vowel-to-Vowel Mismatch: Srak Ue and Srak Aa should not match', () => {
      const expected = 'អឹ'; // Srak Ue
      const recognized = 'អា'; // Srak Aa
      const confidence = 0.8;

      const result = calculatePronunciationScore(expected, recognized, confidence, false);

      expect(result.similarityPercentage).toBe(0.0);
      expect(result.finalScore).toBeLessThan(65.0);
      expect(result.isCorrect).toBe(false);
    });
  });
});
