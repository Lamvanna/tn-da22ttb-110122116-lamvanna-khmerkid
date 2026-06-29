const GameProgress = require('../models/GameProgress');
const mongoose = require('mongoose');

// Helper to determine stars based on score percent
const calculateStars = (score, maxScore = 100) => {
  const percent = (score / maxScore) * 100;
  if (percent >= 90) return 3;
  if (percent >= 60) return 2;
  if (percent >= 30) return 1;
  return 0;
};

// Jaro-Winkler implementation for game 4 (pronunciation similarity)
function getJaroWinklerSimilarity(s1, s2) {
  if (!s1 || !s2) return 0;
  s1 = s1.trim().toLowerCase();
  s2 = s2.trim().toLowerCase();
  if (s1 === s2) return 100;

  const len1 = s1.length;
  const len2 = s2.length;
  const matchWindow = Math.floor(Math.max(len1, len2) / 2) - 1;

  const s1Matches = new Array(len1).fill(false);
  const s2Matches = new Array(len2).fill(false);

  let matches = 0;
  let transpositions = 0;

  for (let i = 0; i < len1; i++) {
    const start = Math.max(0, i - matchWindow);
    const end = Math.min(len2, i + matchWindow + 1);

    for (let j = start; j < end; j++) {
      if (!s2Matches[j] && s1[i] === s2[j]) {
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }
  }

  if (matches === 0) return 0;

  let k = 0;
  for (let i = 0; i < len1; i++) {
    if (s1Matches[i]) {
      while (!s2Matches[k]) k++;
      if (s1[i] !== s2[k]) transpositions++;
      k++;
    }
  }

  const jaro = (matches / len1 + matches / len2 + (matches - transpositions / 2) / matches) / 3;
  
  let prefixLen = 0;
  const maxPrefix = 4;
  for (let i = 0; i < Math.min(len1, len2, maxPrefix); i++) {
    if (s1[i] === s2[i]) prefixLen++;
    else break;
  }

  const jaroWinkler = jaro + prefixLen * 0.1 * (1 - jaro);
  return Math.round(jaroWinkler * 100);
}

class GameProgressController {
  /**
   * GET /api/game-progress/status
   * Lấy trạng thái mở khóa của 4 game cho một ký tự nhất định.
   */
  async getStatus(req, res, next) {
    try {
      const userId = req.user?.id || req.query.userId;
      const { lessonId, characterId } = req.query;

      if (!userId || !lessonId || !characterId) {
        return res.status(400).json({ success: false, error: 'Missing userId, lessonId, or characterId' });
      }

      let progress = await GameProgress.findOne({ userId, lessonId, characterId });
      
      // Nếu chưa tồn tại bản ghi tiến độ, khởi tạo bản ghi mới
      if (!progress) {
        // Tạm thời mặc định unlocked = true cho ký tự đầu tiên của bài học hoặc nếu có cấu hình phù hợp
        progress = new GameProgress({
          userId,
          lessonId,
          characterId,
          unlocked: characterId === '001' ? true : false, 
        });
        await progress.save();
      }

      const response = {
        lessonId: progress.lessonId,
        characterId: progress.characterId,
        unlocked: progress.unlocked,
        games: {
          game1: {
            unlocked: progress.unlocked,
            completed: progress.game1Completed,
            score: progress.game1Score,
            stars: progress.game1Stars,
          },
          game2: {
            unlocked: progress.game1Completed,
            completed: progress.game2Completed,
            score: progress.game2Score,
            stars: progress.game2Stars,
          },
          game3: {
            unlocked: progress.game2Completed,
            completed: progress.game3Completed,
            score: progress.game3Score,
            stars: progress.game3Stars,
          },
          game4: {
            unlocked: progress.game3Completed,
            completed: progress.game4Completed,
            score: progress.game4Score,
            stars: progress.game4Stars,
          },
        },
      };

      return res.status(200).json({ success: true, data: response });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/game-progress/update
   * Lưu điểm số, thời gian và cập nhật tiến trình của từng game.
   */
  async updateProgress(req, res, next) {
    try {
      const userId = req.user?.id || req.body.userId;
      const { lessonId, characterId, gameNum, score, duration, extraData } = req.body;

      if (!userId || !lessonId || !characterId || !gameNum) {
        return res.status(400).json({ success: false, error: 'Missing required fields' });
      }

      let progress = await GameProgress.findOne({ userId, lessonId, characterId });
      if (!progress) {
        progress = new GameProgress({
          userId,
          lessonId,
          characterId,
          unlocked: characterId === '001' ? true : false,
        });
      }

      if (!progress.unlocked) {
        return res.status(403).json({ success: false, error: 'Character level is locked for this user' });
      }

      const currentNum = parseInt(gameNum);

      // Kiểm tra tính tuần tự mở khóa
      if (currentNum === 2 && !progress.game1Completed) {
        return res.status(403).json({ success: false, error: 'Game 2 is locked. Complete Game 1 first.' });
      }
      if (currentNum === 3 && !progress.game2Completed) {
        return res.status(403).json({ success: false, error: 'Game 3 is locked. Complete Game 2 first.' });
      }
      if (currentNum === 4 && !progress.game3Completed) {
        return res.status(403).json({ success: false, error: 'Game 4 is locked. Complete Game 3 first.' });
      }

      const stars = calculateStars(score);

      switch (currentNum) {
        case 1:
          progress.game1Completed = true;
          progress.game1Score = score;
          progress.game1Stars = stars;
          progress.game1Duration = duration || 0;
          progress.game1CompletedAt = new Date();
          break;

        case 2:
          progress.game2Completed = true;
          progress.game2Score = score;
          progress.game2Stars = stars;
          progress.game2WrongAnswers = extraData?.wrongAnswers || 0;
          progress.game2Duration = duration || 0;
          progress.game2CompletedAt = new Date();
          break;

        case 3:
          progress.game3Completed = true;
          progress.game3Score = score;
          progress.game3Stars = stars;
          progress.game3Attempts = extraData?.attempts || 0;
          progress.game3Duration = duration || 0;
          progress.game3CompletedAt = new Date();
          break;

        case 4:
          let simPercentage = 100;
          if (extraData?.spokenText && extraData?.expectedText) {
            simPercentage = getJaroWinklerSimilarity(extraData.spokenText, extraData.expectedText);
          }

          progress.game4Completed = true;
          progress.game4Score = score;
          progress.game4Stars = stars;
          progress.game4Confidence = extraData?.confidence || 1.0;
          progress.game4Similarity = simPercentage;
          progress.game4RecognizedText = extraData?.spokenText || '';
          progress.game4CompletedAt = new Date();

          // Khi game 4 hoàn thành => Mở khóa ký tự tiếp theo trong bài học
          const currentIdNum = parseInt(characterId);
          if (!isNaN(currentIdNum)) {
            const nextCharId = String(currentIdNum + 1).padStart(3, '0');
            let nextProgress = await GameProgress.findOne({ userId, lessonId, characterId: nextCharId });
            if (!nextProgress) {
              nextProgress = new GameProgress({
                userId,
                lessonId,
                characterId: nextCharId,
                unlocked: true,
              });
            } else {
              nextProgress.unlocked = true;
            }
            await nextProgress.save();
          }
          break;

        default:
          return res.status(400).json({ success: false, error: 'Invalid game number (must be 1-4)' });
      }

      await progress.save(); // pre-save tính toán totalScore, totalStars, xp

      return res.status(200).json({
        success: true,
        message: `Updated Game ${currentNum} progress`,
        data: progress,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/game-progress/totals
   * Lấy tổng XP và Stars của user tích lũy từ các game.
   */
  async getTotals(req, res, next) {
    try {
      const userId = req.user?.id || req.query.userId;
      if (!userId) {
        return res.status(400).json({ success: false, error: 'Missing userId parameter' });
      }

      const results = await GameProgress.aggregate([
        { $match: { userId: new mongoose.Types.ObjectId(userId) } },
        {
          $group: {
            _id: '$userId',
            totalXP: { $sum: '$xp' },
            totalStars: { $sum: '$totalStars' },
            totalScore: { $sum: '$totalScore' },
          },
        },
      ]);

      const data = results[0] || {
        _id: userId,
        totalXP: 0,
        totalStars: 0,
        totalScore: 0,
      };

      return res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new GameProgressController();
