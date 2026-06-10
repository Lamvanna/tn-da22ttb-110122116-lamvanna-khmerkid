const mongoose = require('mongoose');

const gameProgressSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    lessonId: {
      type: String,
      required: true,
    },
    characterId: {
      type: String,
      required: true,
    },

    // --- GAME 1: Learn Character ---
    game1Completed: { type: Boolean, default: false },
    game1Score: { type: Number, default: 0 },
    game1Stars: { type: Number, default: 0 },
    game1Duration: { type: Number, default: 0 },
    game1CompletedAt: { type: Date },

    // --- GAME 2: Multiple Choice ---
    game2Completed: { type: Boolean, default: false },
    game2Score: { type: Number, default: 0 },
    game2Stars: { type: Number, default: 0 },
    game2Duration: { type: Number, default: 0 },
    game2WrongAnswers: { type: Number, default: 0 },
    game2CompletedAt: { type: Date },

    // --- GAME 3: Stroke & Puzzle ---
    game3Completed: { type: Boolean, default: false },
    game3Score: { type: Number, default: 0 },
    game3Stars: { type: Number, default: 0 },
    game3Duration: { type: Number, default: 0 },
    game3Attempts: { type: Number, default: 0 },
    game3CompletedAt: { type: Date },

    // --- GAME 4: Pronunciation ---
    game4Completed: { type: Boolean, default: false },
    game4Score: { type: Number, default: 0 },
    game4Stars: { type: Number, default: 0 },
    game4Confidence: { type: Number, default: 0 },
    game4Similarity: { type: Number, default: 0 },
    game4RecognizedText: { type: String, default: '' },
    game4CompletedAt: { type: Date },

    // --- Totals ---
    totalScore: { type: Number, default: 0 },
    totalStars: { type: Number, default: 0 },
    xp: { type: Number, default: 0 },

    // --- Unlock State ---
    unlocked: { type: Boolean, default: false },
  },
  {
    timestamps: true,
  }
);

gameProgressSchema.index({ userId: 1, lessonId: 1, characterId: 1 }, { unique: true });

gameProgressSchema.pre('save', function (next) {
  this.totalScore = this.game1Score + this.game2Score + this.game3Score + this.game4Score;
  this.totalStars = this.game1Stars + this.game2Stars + this.game3Stars + this.game4Stars;
  
  let calculatedXP = 0;
  if (this.game1Completed) calculatedXP += 20;
  if (this.game2Completed) calculatedXP += 30;
  if (this.game3Completed) calculatedXP += 40;
  if (this.game4Completed) calculatedXP += 50;
  
  this.xp = calculatedXP + Math.floor(this.totalScore / 10);
  next();
});

const GameProgress = mongoose.model('GameProgress', gameProgressSchema);

module.exports = GameProgress;
