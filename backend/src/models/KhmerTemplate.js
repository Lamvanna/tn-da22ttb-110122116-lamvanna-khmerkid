/**
 * ========================================
 * Khmer Letter Template Model
 * ========================================
 */

const mongoose = require('mongoose');

const khmerTemplateSchema = new mongoose.Schema(
  {
    character: {
      type: String,
      required: true,
      unique: true,
    },
    strokeCount: {
      type: Number,
      required: true,
    },
    difficulty: {
      type: Number,
      default: 1,
    },
    templateStrokes: [
      {
        strokeIndex: Number,
        direction: String,
        points: [
          {
            x: Number,
            y: Number,
          }
        ],
      }
    ],
    gridOccupancy: [
      {
        type: Number,
      }
    ],
    metadata: {
      createdBy: String,
      version: {
        type: Number,
        default: 1,
      },
    },
  },
  {
    timestamps: true,
  }
);

khmerTemplateSchema.index({ character: 1 });

const KhmerTemplate = mongoose.model('KhmerTemplate', khmerTemplateSchema);

module.exports = KhmerTemplate;
