/**
 * ========================================
 * Khmer Stroke Template Routes
 * ========================================
 */

const router = require('express').Router();
const KhmerTemplate = require('../models/KhmerTemplate');

// GET /api/templates - Get all templates
router.get('/', async (req, res) => {
  try {
    const templates = await KhmerTemplate.find();
    res.json({
      success: true,
      count: templates.length,
      data: templates,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve templates',
      error: err.message,
    });
  }
});

// GET /api/templates/:char - Get template for specific character
router.get('/:char', async (req, res) => {
  try {
    const template = await KhmerTemplate.findOne({ character: req.params.char });
    if (!template) {
      return res.status(404).json({
        success: false,
        message: `Template for '${req.params.char}' not found`,
      });
    }
    res.json({
      success: true,
      data: template,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Error fetching template',
      error: err.message,
    });
  }
});

// POST /api/templates - Create/Update template
router.post('/', async (req, res) => {
  const { character, strokeCount, difficulty, templateStrokes, gridOccupancy, createdBy } = req.body;
  if (!character || !strokeCount) {
    return res.status(400).json({
      success: false,
      message: 'Character and strokeCount are required fields',
    });
  }

  try {
    const filter = { character };
    const update = {
      character,
      strokeCount,
      difficulty: difficulty || 1,
      templateStrokes: templateStrokes || [],
      gridOccupancy: gridOccupancy || [],
      metadata: {
        createdBy: createdBy || 'admin',
        version: 1,
      },
    };
    
    // Upsert template
    const template = await KhmerTemplate.findOneAndUpdate(filter, update, {
      new: true,
      upsert: true,
      runValidators: true,
    });

    res.status(200).json({
      success: true,
      message: `Template for '${character}' updated successfully`,
      data: template,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Error saving template',
      error: err.message,
    });
  }
});

module.exports = router;
