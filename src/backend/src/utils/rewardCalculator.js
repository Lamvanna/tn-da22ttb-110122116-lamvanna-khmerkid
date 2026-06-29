/**
 * Tích hợp hệ thống tính toán phần thưởng (Sao, Sao thưởng, XP, Perfect Reward)
 * dành cho các trò chơi Khmer.
 */

/**
 * Tính số Sao cơ bản dựa trên số câu trả lời đúng.
 * stars = correctAnswers
 * 
 * @param {number} correctAnswers - Số câu trả lời đúng (0 - 20)
 * @returns {number} Số Sao cơ bản đạt được
 */
function calculateStars(correctAnswers) {
  validateCorrectAnswers(correctAnswers);
  if (correctAnswers <= 2) return 0;
  if (correctAnswers <= 4) return 1;
  if (correctAnswers <= 6) return 2;
  if (correctAnswers <= 8) return 3;
  if (correctAnswers <= 10) return 5;
  if (correctAnswers === 11) return 7;
  if (correctAnswers === 12) return 9;
  if (correctAnswers === 13) return 11;
  if (correctAnswers === 14) return 13;
  if (correctAnswers === 15) return 15;
  if (correctAnswers === 16) return 17;
  if (correctAnswers === 17) return 18;
  if (correctAnswers === 18) return 19;
  return 20;
}

/**
 * Tính số Sao thưởng (Bonus Stars) dựa trên số câu trả lời đúng.
 * Đúng từ 17 câu trở lên sẽ nhận thêm Sao Thưởng.
 * 17 -> +5
 * 18 -> +8
 * 19 -> +12
 * 20 -> +20
 * Khác -> 0
 * 
 * @param {number} correctAnswers - Số câu trả lời đúng (0 - 20)
 * @returns {number} Số Sao thưởng đạt được
 */
function calculateBonusStars(correctAnswers) {
  validateCorrectAnswers(correctAnswers);
  return 0;
}

/**
 * Tính số XP cơ bản.
 * Mỗi câu đúng được +10 XP.
 * 
 * @param {number} correctAnswers - Số câu trả lời đúng (0 - 20)
 * @returns {number} Số XP đạt được
 */
function calculateXP(correctAnswers) {
  validateCorrectAnswers(correctAnswers);
  const stars = calculateStars(correctAnswers);
  return Math.round((stars / 20) * 70);
}

/**
 * Tính toán phần thưởng Perfect Reward khi đạt điểm tuyệt đối 20/20.
 * +20 Bonus Stars
 * +100 Bonus XP
 * +Perfect Badge
 * 
 * @param {number} correctAnswers - Số câu trả lời đúng (0 - 20)
 * @returns {Object} Đối tượng mô tả phần thưởng Perfect
 */
function calculatePerfectReward(correctAnswers) {
  validateCorrectAnswers(correctAnswers);
  if (correctAnswers === 20) {
    return {
      perfectBadge: true,
      bonusStars: 0,
      bonusXP: 0,
    };
  }
  return {
    perfectBadge: false,
    bonusStars: 0,
    bonusXP: 0,
  };
}

/**
 * Hàm kiểm tra tính hợp lệ của số câu đúng.
 * Không cho phép số câu đúng > 20, < 0, hoặc không phải số nguyên.
 * 
 * @param {number} correctAnswers 
 */
function validateCorrectAnswers(correctAnswers) {
  if (typeof correctAnswers !== 'number' || isNaN(correctAnswers)) {
    throw new Error('Số câu trả lời đúng phải là số hợp lệ.');
  }
  if (!Number.isInteger(correctAnswers)) {
    throw new Error('Số câu trả lời đúng phải là số nguyên.');
  }
  if (correctAnswers < 0) {
    throw new Error('Số câu trả lời đúng không được phép âm.');
  }
  if (correctAnswers > 20) {
    throw new Error('Số câu trả lời đúng không được phép vượt quá 20.');
  }
}

module.exports = {
  calculateStars,
  calculateBonusStars,
  calculateXP,
  calculatePerfectReward,
  validateCorrectAnswers,
};
