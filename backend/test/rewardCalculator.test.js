/**
 * ========================================
 * Jest Unit Tests - rewardCalculator
 * ========================================
 */

const {
  calculateStars,
  calculateBonusStars,
  calculateXP,
  calculatePerfectReward,
} = require('../src/utils/rewardCalculator');

describe('Khmer Kids Game Rewards System Tests', () => {
  describe('calculateStars', () => {
    test('should return stars equal to correct answers for valid inputs', () => {
      expect(calculateStars(0)).toBe(0);
      expect(calculateStars(5)).toBe(5);
      expect(calculateStars(10)).toBe(10);
      expect(calculateStars(15)).toBe(15);
      expect(calculateStars(20)).toBe(20);
    });

    test('should throw error if correctAnswers is greater than 20', () => {
      expect(() => calculateStars(21)).toThrow('Số câu trả lời đúng không được phép vượt quá 20.');
      expect(() => calculateStars(100)).toThrow('Số câu trả lời đúng không được phép vượt quá 20.');
    });

    test('should throw error if correctAnswers is negative', () => {
      expect(() => calculateStars(-1)).toThrow('Số câu trả lời đúng không được phép âm.');
      expect(() => calculateStars(-10)).toThrow('Số câu trả lời đúng không được phép âm.');
    });

    test('should throw error if correctAnswers is not an integer', () => {
      expect(() => calculateStars(10.5)).toThrow('Số câu trả lời đúng phải là số nguyên.');
      expect(() => calculateStars('10')).toThrow('Số câu trả lời đúng phải là số hợp lệ.');
      expect(() => calculateStars(null)).toThrow('Số câu trả lời đúng phải là số hợp lệ.');
      expect(() => calculateStars(undefined)).toThrow('Số câu trả lời đúng phải là số hợp lệ.');
    });
  });

  describe('calculateBonusStars', () => {
    test('should return 0 bonus stars for correct answers under 17', () => {
      expect(calculateBonusStars(0)).toBe(0);
      expect(calculateBonusStars(10)).toBe(0);
      expect(calculateBonusStars(15)).toBe(0);
      expect(calculateBonusStars(16)).toBe(0);
    });

    test('should return correct bonus stars according to the reward table', () => {
      expect(calculateBonusStars(17)).toBe(5);
      expect(calculateBonusStars(18)).toBe(8);
      expect(calculateBonusStars(19)).toBe(12);
      expect(calculateBonusStars(20)).toBe(20);
    });

    test('should throw error for out-of-bounds inputs', () => {
      expect(() => calculateBonusStars(-5)).toThrow();
      expect(() => calculateBonusStars(25)).toThrow();
    });
  });

  describe('calculateXP', () => {
    test('should return correct basic XP (+10 per correct answer)', () => {
      expect(calculateXP(0)).toBe(0);
      expect(calculateXP(1)).toBe(10);
      expect(calculateXP(10)).toBe(100);
      expect(calculateXP(15)).toBe(150);
      expect(calculateXP(20)).toBe(200);
    });

    test('should throw error for out-of-bounds inputs', () => {
      expect(() => calculateXP(-1)).toThrow();
      expect(() => calculateXP(21)).toThrow();
    });
  });

  describe('calculatePerfectReward', () => {
    test('should return perfect badge and bonuses if score is 20/20', () => {
      const reward = calculatePerfectReward(20);
      expect(reward).toEqual({
        perfectBadge: true,
        bonusStars: 20,
        bonusXP: 100,
      });
    });

    test('should return no badge and zero bonuses if score is less than 20', () => {
      const reward = calculatePerfectReward(19);
      expect(reward).toEqual({
        perfectBadge: false,
        bonusStars: 0,
        bonusXP: 0,
      });

      expect(calculatePerfectReward(0)).toEqual({
        perfectBadge: false,
        bonusStars: 0,
        bonusXP: 0,
      });
    });

    test('should throw error for out-of-bounds inputs', () => {
      expect(() => calculatePerfectReward(-2)).toThrow();
      expect(() => calculatePerfectReward(22)).toThrow();
    });
  });
});
