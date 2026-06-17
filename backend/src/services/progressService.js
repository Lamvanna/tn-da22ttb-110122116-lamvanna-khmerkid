/**
 * ========================================
 * Progress Service
 * ========================================
 * 
 * Business logic for offline-first progress sync.
 * Handles bidirectional merge with take-max strategy.
 */

const Progress = require('../models/Progress');
const User = require('../models/User');
const { AppError } = require('../middlewares/errorHandler');

class ProgressService {
  /**
   * Get or create progress document for user
   */
  async getOrCreateProgress(userId) {
    let progress = await Progress.findOne({ userId });
    if (!progress) {
      progress = await Progress.create({
        userId,
        completedLessons: [],
        unlockedLessons: [],
        gameResults: [],
        achievements: [],
      });
    }
    return progress;
  }

  /**
   * GET /api/progress/get — Lấy toàn bộ progress
   */
  async getProgress(userId) {
    const progress = await this.getOrCreateProgress(userId);
    const user = await User.findById(userId)
      .populate('badges')
      .populate('achievements');

    return {
      completedLessons: progress.completedLessons,
      unlockedLessons: progress.unlockedLessons,
      gameResults: progress.gameResults,
      achievements: progress.achievements,
      lastSyncAt: progress.lastSyncAt,
      profile: user ? {
        xp: user.xp,
        stars: user.stars,
        streak: user.streak,
        level: user.level,
        name: user.name,
        avatar: user.avatar,
        learningProgress: user.learningProgress,
      } : null,
    };
  }

  /**
   * POST /api/progress/sync — Bidirectional sync (take-max strategy)
   */
  async syncProgress(userId, clientData) {
    const progress = await this.getOrCreateProgress(userId);
    const clientLessons = clientData.completedLessons || [];

    // ═══════════════════════════════════════════════════
    // MERGE: Take-max strategy
    // ═══════════════════════════════════════════════════

    // Build server map { lessonId -> lessonData }
    const serverMap = new Map();
    for (const lesson of progress.completedLessons) {
      serverMap.set(lesson.lessonId, lesson);
    }

    // Merge client lessons vào server
    for (const clientLesson of clientLessons) {
      const existing = serverMap.get(clientLesson.lessonId);
      
      if (existing) {
        // Take max stars
        existing.stars = Math.max(existing.stars || 0, clientLesson.stars || 0);
        // Union completed
        existing.isCompleted = existing.isCompleted || clientLesson.isCompleted;
        // Keep earliest completedAt
        if (clientLesson.completedAt && (!existing.completedAt || new Date(clientLesson.completedAt) < existing.completedAt)) {
          existing.completedAt = new Date(clientLesson.completedAt);
        }
      } else {
        // Add new lesson from client
        serverMap.set(clientLesson.lessonId, {
          lessonId: clientLesson.lessonId,
          lessonType: clientLesson.lessonType || '',
          lessonOrder: clientLesson.lessonOrder || 0,
          stars: clientLesson.stars || 0,
          isCompleted: clientLesson.isCompleted || false,
          completedAt: clientLesson.completedAt ? new Date(clientLesson.completedAt) : new Date(),
        });
      }
    }

    // Convert map back to array
    const mergedLessons = Array.from(serverMap.values());

    // ═══════════════════════════════════════════════════
    // MERGE: Unlocked lessons (union)
    // ═══════════════════════════════════════════════════
    const clientUnlocked = clientData.unlockedLessons || [];
    const mergedUnlocked = [...new Set([
      ...progress.unlockedLessons,
      ...clientUnlocked,
      // Auto-unlock: mọi bài completed đều unlock
      ...mergedLessons.filter(l => l.isCompleted).map(l => l.lessonId),
    ])];

    // ═══════════════════════════════════════════════════
    // SAVE merged progress
    // ═══════════════════════════════════════════════════
    progress.completedLessons = mergedLessons;
    progress.unlockedLessons = mergedUnlocked;
    progress.lastSyncAt = new Date();
    await progress.save();

    // Update User model completedLessons count and list of completed lesson IDs
    const completedCount = mergedLessons.filter(l => l.isCompleted).length;
    const completedLessonIds = mergedLessons
      .filter(l => l.isCompleted && l.lessonId && l.lessonId.match(/^[0-9a-fA-F]{24}$/))
      .map(l => l.lessonId);

    await User.findByIdAndUpdate(userId, {
      'learningProgress.totalLessonsCompleted': completedCount,
      'learningProgress.completedLessons': completedLessonIds,
    });

    // Return merged data cho client update local
    const user = await User.findById(userId);
    return {
      completedLessons: mergedLessons.map(l => ({
        lessonId: l.lessonId,
        lessonType: l.lessonType,
        lessonOrder: l.lessonOrder,
        stars: l.stars,
        isCompleted: l.isCompleted,
        isUnlocked: true,
        completedAt: l.completedAt,
      })),
      unlockedLessons: mergedUnlocked,
      profile: user ? {
        xp: user.xp,
        stars: user.stars,
        streak: user.streak,
        level: user.level,
      } : null,
    };
  }

  /**
   * POST /api/progress/complete — Hoàn thành 1 bài học
   */
  async completeLesson(userId, lessonId, stars, lessonType, lessonOrder = null) {
    const progress = await this.getOrCreateProgress(userId);

    // Tự động phân giải lessonOrder và lessonType nếu thiếu
    let resolvedOrder = lessonOrder;
    let resolvedType = lessonType;

    if (resolvedOrder === null || resolvedOrder === undefined) {
      if (lessonId && lessonId.match(/^[0-9a-fA-F]{24}$/)) {
        const Lesson = require('../models/Lesson');
        const dbLesson = await Lesson.findById(lessonId);
        if (dbLesson) {
          resolvedOrder = dbLesson.order;
          if (!resolvedType) resolvedType = dbLesson.type;
        }
      } else if (lessonId && lessonId.includes('_')) {
        const parts = lessonId.split('_');
        const numPart = parseInt(parts[parts.length - 1], 10);
        if (!isNaN(numPart)) {
          resolvedOrder = numPart;
        }
        if (!resolvedType) {
          resolvedType = parts.slice(0, -1).join('_');
        }
      }
    }

    if (resolvedOrder === null || resolvedOrder === undefined) {
      resolvedOrder = 0;
    }

    // Tìm lesson trong progress
    const existingIdx = progress.completedLessons.findIndex(
      l => l.lessonId === lessonId
    );

    if (existingIdx >= 0) {
      // Update — take max stars
      const existing = progress.completedLessons[existingIdx];
      existing.stars = Math.max(existing.stars || 0, stars);
      existing.isCompleted = true;
      existing.lessonOrder = resolvedOrder;
      if (resolvedType) {
        existing.lessonType = resolvedType;
      }
      if (!existing.completedAt) {
        existing.completedAt = new Date();
      }
    } else {
      // Add new
      progress.completedLessons.push({
        lessonId,
        lessonType: resolvedType || '',
        lessonOrder: resolvedOrder,
        stars,
        isCompleted: true,
        completedAt: new Date(),
      });
    }

    // Auto-unlock
    if (!progress.unlockedLessons.includes(lessonId)) {
      progress.unlockedLessons.push(lessonId);
    }

    progress.lastSyncAt = new Date();
    await progress.save();

    // Update User gamification
    const user = await User.findById(userId);
    if (user) {
      // Add XP & stars
      const xpGain = stars * 5;
      const starsGain = stars;
      user.xp += xpGain;
      user.stars += starsGain;

      // Update completed count
      const completedCount = progress.completedLessons.filter(l => l.isCompleted).length;
      user.learningProgress.totalLessonsCompleted = completedCount;

      // Add to user's completedLessons if it's a real MongoDB ObjectId
      if (lessonId.match(/^[0-9a-fA-F]{24}$/)) {
        const mongoose = require('mongoose');
        const objectId = new mongoose.Types.ObjectId(lessonId);
        if (!user.learningProgress.completedLessons.includes(objectId)) {
          user.learningProgress.completedLessons.push(objectId);
        }
      }

      await user.save();

      return {
        lessonId,
        stars,
        xpGained: xpGain,
        starsGained: starsGain,
        totalXp: user.xp,
        totalStars: user.stars,
        totalCompleted: completedCount,
      };
    }

    return { lessonId, stars };
  }

  /**
   * POST /api/progress/unlock — Mở khóa bài học
   */
  async unlockLesson(userId, lessonId) {
    const progress = await this.getOrCreateProgress(userId);

    if (!progress.unlockedLessons.includes(lessonId)) {
      progress.unlockedLessons.push(lessonId);
      progress.lastSyncAt = new Date();
      await progress.save();
    }

    return { lessonId, unlocked: true };
  }
}

module.exports = new ProgressService();
