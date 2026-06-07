/**
 * ========================================
 * TTS Routes
 * ========================================
 */

const router = require('express').Router();
const ttsController = require('../controllers/ttsController');
const { authenticate } = require('../middlewares/auth');

// POST /api/tts/synthesize
router.post('/synthesize', authenticate, ttsController.synthesize);

module.exports = router;
