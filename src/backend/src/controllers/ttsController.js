/**
 * ========================================
 * TTS Controller
 * ========================================
 */

const TextToSpeechService = require('../services/TextToSpeechService');

class TtsController {
  /** POST /api/tts/synthesize */
  async synthesize(req, res, next) {
    try {
      const { text, locale } = req.body;
      if (!text) {
        return res.status(400).json({ success: false, message: 'Văn bản cần đọc là bắt buộc!' });
      }

      const audioBuffer = await TextToSpeechService.synthesize(text, locale || 'km');

      res.set({
        'Content-Type': 'audio/mpeg',
        'Content-Length': audioBuffer.length,
        'Cache-Control': 'public, max-age=2592000', // 30 days HTTP caching
      });

      res.send(audioBuffer);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new TtsController();
