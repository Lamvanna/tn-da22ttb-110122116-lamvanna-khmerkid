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
    test('should return stars according to the new reward mapping for valid inputs', () => {
      // 0 - 2 correct -> 0⭐
      expect(calculateStars(0)).toBe(0);
      expect(calculateStars(1)).toBe(0);
      expect(calculateStars(2)).toBe(0);
      
      // 3 - 4 correct -> 1⭐
      expect(calculateStars(3)).toBe(1);
      expect(calculateStars(4)).toBe(1);

      // 5 - 6 correct -> 2⭐
      expect(calculateStars(5)).toBe(2);
      expect(calculateStars(6)).toBe(2);

      // 7 - 8 correct -> 3⭐
      expect(calculateStars(7)).toBe(3);
      expect(calculateStars(8)).toBe(3);

      // 9 - 10 correct -> 5⭐
      expect(calculateStars(9)).toBe(5);
      expect(calculateStars(10)).toBe(5);

      // 11 correct -> 7⭐
      expect(calculateStars(11)).toBe(7);

      // 12 correct -> 9⭐
      expect(calculateStars(12)).toBe(9);

      // 13 correct -> 11⭐
      expect(calculateStars(13)).toBe(11);

      // 14 correct -> 13⭐
      expect(calculateStars(14)).toBe(13);

      // 15 correct -> 15⭐
      expect(calculateStars(15)).toBe(15);

      // 16 correct -> 17⭐
      expect(calculateStars(16)).toBe(17);

      // 17 correct -> 18⭐
      expect(calculateStars(17)).toBe(18);

      // 18 correct -> 19⭐
      expect(calculateStars(18)).toBe(19);

      // 19 - 20 correct -> 20⭐
      expect(calculateStars(19)).toBe(20);
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
    test('should return 0 bonus stars for any correct answers (bonus merged into base stars)', () => {
      expect(calculateBonusStars(0)).toBe(0);
      expect(calculateBonusStars(10)).toBe(0);
      expect(calculateBonusStars(15)).toBe(0);
      expect(calculateBonusStars(17)).toBe(0);
      expect(calculateBonusStars(20)).toBe(0);
    });

    test('should throw error for out-of-bounds inputs', () => {
      expect(() => calculateBonusStars(-5)).toThrow();
      expect(() => calculateBonusStars(25)).toThrow();
    });
  });

  describe('calculateXP', () => {
    test('should return correct XP based on stars achieved (XP = Math.round(stars / 20 * 70))', () => {
      // 0 - 2 correct -> 0 stars -> 0 XP
      expect(calculateXP(0)).toBe(0);
      expect(calculateXP(2)).toBe(0);
      
      // 3 - 4 correct -> 1 star -> 4 XP
      expect(calculateXP(3)).toBe(4);
      
      // 9 - 10 correct -> 5 stars -> 18 XP
      expect(calculateXP(10)).toBe(18);

      // 15 correct -> 15 stars -> 53 XP
      expect(calculateXP(15)).toBe(53);

      // 20 correct -> 20 stars -> 70 XP
      expect(calculateXP(20)).toBe(70);
    });

    test('should throw error for out-of-bounds inputs', () => {
      expect(() => calculateXP(-1)).toThrow();
      expect(() => calculateXP(21)).toThrow();
    });
  });

  describe('calculatePerfectReward', () => {
    test('should return perfect badge and zero bonus rewards if score is 20/20', () => {
      const reward = calculatePerfectReward(20);
      expect(reward).toEqual({
        perfectBadge: true,
        bonusStars: 0,
        bonusXP: 0,
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
