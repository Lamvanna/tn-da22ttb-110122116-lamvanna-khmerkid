/**
 * ========================================
 * Mission Controller
 * ========================================
 */

const missionService = require('../services/missionService');
const badgeService = require('../services/badgeService');
const rankService = require('../services/rankService');
const uploadService = require('../services/uploadService');
const { sendSuccess } = require('../utils/response');
const { MESSAGES } = require('../constants');

class MissionController {
  /** GET /api/missions */
  async getMissions(req, res, next) {
    try {
      const missions = await missionService.getMissions(req.user._id);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, missions);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/missions/claim */
  async claimReward(req, res, next) {
    try {
      const { missionId } = req.body;
      const result = await missionService.claimReward(req.user._id, missionId);
      sendSuccess(res, MESSAGES.MISSION_CLAIMED, result);
    } catch (error) {
      next(error);
    }
  }
}

// ========================================
// Badge & Rank Controllers (co-located)
// ========================================

class BadgeController {
  /** GET /api/badges */
  async getBadges(req, res, next) {
    try {
      const badges = await badgeService.getAllBadges();
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, badges);
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/achievements */
  async getAchievements(req, res, next) {
    try {
      const achievements = await badgeService.getUserAchievements(req.user._id);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, achievements);
    } catch (error) {
      next(error);
    }
  }
}

class RankController {
  /** GET /api/rank/top */
  async getTopRanking(req, res, next) {
    try {
      const ranking = await rankService.getTopRanking(parseInt(req.query.limit) || 20);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, ranking);
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/rank/weekly */
  async getWeeklyRanking(req, res, next) {
    try {
      const ranking = await rankService.getWeeklyRanking(parseInt(req.query.limit) || 20);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, ranking);
    } catch (error) {
      next(error);
    }
  }

  /** GET /api/rank/monthly */
  async getMonthlyRanking(req, res, next) {
    try {
      const ranking = await rankService.getMonthlyRanking(parseInt(req.query.limit) || 20);
      sendSuccess(res, MESSAGES.FETCH_SUCCESS, ranking);
    } catch (error) {
      next(error);
    }
  }
}

class UploadController {
  /** POST /api/upload/image */
  async uploadImage(req, res, next) {
    try {
      const result = await uploadService.processImageUpload(req.file);
      sendSuccess(res, MESSAGES.UPLOAD_SUCCESS, result);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/upload/audio */
  async uploadAudio(req, res, next) {
    try {
      const result = await uploadService.processAudioUpload(req.file);
      sendSuccess(res, MESSAGES.UPLOAD_SUCCESS, result);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/upload/pdf */
  async uploadPdf(req, res, next) {
    try {
      const result = await uploadService.processPdfUpload(req.file);
      sendSuccess(res, MESSAGES.UPLOAD_SUCCESS, result);
    } catch (error) {
      next(error);
    }
  }

  /** POST /api/upload/video */
  async uploadVideo(req, res, next) {
    try {
      const result = await uploadService.processVideoUpload(req.file);
      sendSuccess(res, MESSAGES.UPLOAD_SUCCESS, result);
    } catch (error) {
      next(error);
    }
  }

  /** DELETE /api/upload/:publicId */
  async deleteFile(req, res, next) {
    try {
      const { publicId } = req.params;
      const resourceType = req.query.type || 'image';
      await uploadService.deleteFile(publicId, resourceType);
      sendSuccess(res, MESSAGES.DELETE_FILE_SUCCESS);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = {
  missionController: new MissionController(),
  badgeController: new BadgeController(),
  rankController: new RankController(),
  uploadController: new UploadController(),
};
