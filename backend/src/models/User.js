/**
 * ========================================
 * User Model
 * ========================================
 * 
 * Full user schema with gamification fields,
 * learning progress tracking, and auth support.
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { ROLES, AUTH_PROVIDERS } = require('../constants');

const userSchema = new mongoose.Schema(
  {
    // ========================================
    // Basic Info
    // ========================================
    name: {
      type: String,
      required: [true, 'Tên là bắt buộc'],
      trim: true,
      maxlength: [50, 'Tên không quá 50 ký tự'],
    },
    email: {
      type: String,
      required: [true, 'Email là bắt buộc'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Email không hợp lệ'],
    },
    password: {
      type: String,
      minlength: [6, 'Mật khẩu tối thiểu 6 ký tự'],
      select: false, // Don't include in queries by default
    },
    avatar: {
      type: String,
      default: '',
    },

    // ========================================
    // Auth
    // ========================================
    role: {
      type: String,
      enum: Object.values(ROLES),
      default: ROLES.USER,
    },
    authProvider: {
      type: String,
      enum: Object.values(AUTH_PROVIDERS),
      default: AUTH_PROVIDERS.LOCAL,
    },
    googleId: {
      type: String,
      sparse: true,
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    refreshToken: {
      type: String,
      select: false,
    },
    passwordResetToken: String,
    passwordResetExpires: Date,

    // ========================================
    // Gamification
    // ========================================
    level: {
      type: Number,
      default: 1,
      min: 1,
    },
    xp: {
      type: Number,
      default: 0,
      min: 0,
    },
    stars: {
      type: Number,
      default: 0,
      min: 0,
    },
    streak: {
      type: Number,
      default: 0,
      min: 0,
    },
    longestStreak: {
      type: Number,
      default: 0,
      min: 0,
    },

    // ========================================
    // Badges & Achievements
    // ========================================
    badges: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Badge',
    }],
    achievements: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Achievement',
    }],

    // ========================================
    // Ranking
    // ========================================
    rank: {
      type: Number,
      default: 0,
    },

    // ========================================
    // Learning Progress
    // ========================================
    learningProgress: {
      // Overall progress
      totalLessonsCompleted: { type: Number, default: 0 },
      totalGamesPlayed: { type: Number, default: 0 },
      totalStudyTime: { type: Number, default: 0 }, // in minutes

      // Skill levels (0-100)
      listeningLevel: { type: Number, default: 0, min: 0, max: 100 },
      speakingLevel: { type: Number, default: 0, min: 0, max: 100 },
      readingLevel: { type: Number, default: 0, min: 0, max: 100 },
      writingLevel: { type: Number, default: 0, min: 0, max: 100 },

      // Completed lessons by type
      completedLessons: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Lesson',
      }],

      // Weak skills for adaptive learning
      weakSkills: [{
        skill: String,
        score: Number,
        lastPracticed: Date,
      }],
    },
    inventory: {
      hints: { type: Number, default: 2 },
      timePowerups: { type: Number, default: 2 },
      livesPowerups: { type: Number, default: 1 },
      doubleScorePowerups: { type: Number, default: 1 },
      hintsLastReg: { type: Number, default: Date.now },
      timePowerupsLastReg: { type: Number, default: Date.now },
      livesPowerupsLastReg: { type: Number, default: Date.now },
      doubleScorePowerupsLastReg: { type: Number, default: Date.now },
    },

    // ========================================
    // Activity Tracking
    // ========================================
    lastLoginDate: {
      type: Date,
      default: Date.now,
    },
    lastActiveDate: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ========================================
// Indexes
// ========================================
userSchema.index({ rank: 1 });
userSchema.index({ xp: -1 });
userSchema.index({ level: -1 });

userSchema.pre('save', async function (next) {
  if (this.isModified('xp')) {
    const { calculateLevel } = require('../utils/helpers');
    const levelInfo = calculateLevel(this.xp);
    this.level = levelInfo.level;
  }
  next();
});

// ========================================
// Pre-save: Hash password
// ========================================
userSchema.pre('save', async function (next) {
  // Only hash password if it was modified
  if (!this.isModified('password')) return next();

  // Skip if no password (Google auth)
  if (!this.password) return next();

  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// ========================================
// Methods
// ========================================

/**
 * Compare password for login
 */
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

/**
 * Transform user document for API response (hide sensitive fields)
 */
userSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  delete user.refreshToken;
  delete user.passwordResetToken;
  delete user.passwordResetExpires;
  delete user.__v;
  return user;
};

// ========================================
// Virtuals
// ========================================
userSchema.virtual('totalBadges').get(function () {
  return this.badges ? this.badges.length : 0;
});

const User = mongoose.model('User', userSchema);

module.exports = User;
