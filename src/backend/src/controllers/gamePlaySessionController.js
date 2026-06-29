const GamePlaySession = require('../models/GamePlaySession');
const User = require('../models/User');
const rewardCalculator = require('../utils/rewardCalculator');
const userService = require('../services/userService');
const Badge = require('../models/Badge');

class GamePlaySessionController {
  /**
   * API 5: Lưu kết quả trò chơi
   * POST /api/game-play-sessions
   */
  async saveGameSession(req, res, next) {
    try {
      const userId = req.user._id;
      const { lessonId, characterId, correctAnswers, wrongAnswers } = req.body;

      // 1. Validation dữ liệu đầu vào
      if (!lessonId || !characterId) {
        return res.status(400).json({
          success: false,
          message: 'lessonId và characterId là bắt buộc.',
        });
      }

      if (typeof correctAnswers !== 'number' || typeof wrongAnswers !== 'number') {
        return res.status(400).json({
          success: false,
          message: 'correctAnswers và wrongAnswers phải là số.',
        });
      }

      // Kiểm tra các ràng buộc theo yêu cầu đề bài
      try {
        rewardCalculator.validateCorrectAnswers(correctAnswers);
      } catch (err) {
        return res.status(400).json({
          success: false,
          message: err.message,
        });
      }

      if (wrongAnswers < 0) {
        return res.status(400).json({
          success: false,
          message: 'Số câu trả lời sai không được phép âm.',
        });
      }

      if (correctAnswers + wrongAnswers !== 20) {
        return res.status(400).json({
          success: false,
          message: `Tổng số câu trả lời đúng và sai phải bằng 20 (Nhận được: ${correctAnswers + wrongAnswers}).`,
        });
      }

      // 2. Tính toán phần thưởng
      const stars = rewardCalculator.calculateStars(correctAnswers);
      const bonusStars = rewardCalculator.calculateBonusStars(correctAnswers);
      const totalStars = stars + bonusStars;

      const xp = rewardCalculator.calculateXP(correctAnswers);
      const perfectInfo = rewardCalculator.calculatePerfectReward(correctAnswers);
      const bonusXP = perfectInfo.bonusXP; // +100 XP nếu 20/20
      const totalXP = xp + bonusXP;

      const perfectReward = perfectInfo.perfectBadge; // true/false

      // 3. Lưu bản ghi GamePlaySession
      const session = await GamePlaySession.create({
        userId,
        lessonId,
        characterId,
        totalQuestions: 20,
        correctAnswers,
        wrongAnswers,
        stars,
        bonusStars,
        totalStars,
        xp,
        bonusXP,
        totalXP,
        perfectReward,
        completedAt: new Date(),
      });

      // 4. Cộng dồn vào thông tin User
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy người dùng.',
        });
      }

      // Cộng dồn tổng Sao và tổng XP
      user.stars += totalStars;
      
      // Sử dụng userService.addXP để xử lý cộng XP và tự động tăng level (Level Up)
      const io = req.app.get('io') || null;
      await userService.addXP(userId, totalXP, io);

      // Nếu đạt Perfect (20/20), trao Perfect Badge nếu chưa sở hữu
      if (perfectReward) {
        let perfectBadge = await Badge.findOne({ name: 'Huy hiệu Hoàn hảo' });
        if (!perfectBadge) {
          // Tạo badge nếu chưa có
          perfectBadge = await Badge.create({
            name: 'Huy hiệu Hoàn hảo',
            description: 'Đạt điểm tuyệt đối 20/20 trong một trò chơi bất kỳ!',
            type: 'learning',
            xpReward: 100,
            starsReward: 20,
            order: 100,
            iconUrl: 'https://res.cloudinary.com/demo/image/upload/v1625070000/badges/perfect_badge.png',
            isActive: true,
          });
        }

        // Kiểm tra xem user đã có badge này chưa
        if (!user.badges.includes(perfectBadge._id)) {
          user.badges.push(perfectBadge._id);
        }
      }

      await user.save();

      return res.status(201).json({
        success: true,
        message: 'Lưu kết quả trò chơi thành công và đã cập nhật phần thưởng cho tài khoản.',
        data: session,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * API 6: Cộng dồn tổng Sao của người dùng
   * POST /api/users/accumulate-stars
   */
  async accumulateStars(req, res, next) {
    try {
      const userId = req.user._id;
      const { stars } = req.body;

      if (typeof stars !== 'number' || isNaN(stars) || !Number.isInteger(stars)) {
        return res.status(400).json({
          success: false,
          message: 'Số Sao cộng dồn phải là một số nguyên hợp lệ.',
        });
      }

      if (stars < 0) {
        return res.status(400).json({
          success: false,
          message: 'Số Sao cộng dồn không được âm.',
        });
      }

      const user = await userService.addStars(userId, stars);

      return res.status(200).json({
        success: true,
        message: 'Cộng dồn Sao thành công.',
        data: {
          userId: user._id,
          totalStars: user.stars,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * API 7: Cộng dồn tổng XP của người dùng
   * POST /api/users/accumulate-xp
   */
  async accumulateXP(req, res, next) {
    try {
      const userId = req.user._id;
      const { xp } = req.body;

      if (typeof xp !== 'number' || isNaN(xp) || !Number.isInteger(xp)) {
        return res.status(400).json({
          success: false,
          message: 'Số XP cộng dồn phải là một số nguyên hợp lệ.',
        });
      }

      if (xp < 0) {
        return res.status(400).json({
          success: false,
          message: 'Số XP cộng dồn không được âm.',
        });
      }

      const io = req.app.get('io') || null;
      const { user, leveledUp, newLevel } = await userService.addXP(userId, xp, io);

      return res.status(200).json({
        success: true,
        message: 'Cộng dồn XP thành công.',
        data: {
          userId: user._id,
          totalXP: user.xp,
          level: user.level,
          leveledUp,
          newLevel,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new GamePlaySessionController();
