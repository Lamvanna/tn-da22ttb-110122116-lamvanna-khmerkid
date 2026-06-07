/**
 * ========================================
 * Pronunciation Router
 * ========================================
 * 
 * Defines the route for pronunciation checking,
 * applying rate-limiting and file upload middlewares.
 */

const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const upload = require('../middlewares/upload.middleware');
const { checkPronunciation } = require('../controllers/pronunciation.controller');
const errorHandler = require('../middlewares/errorHandler.middleware');

// Cấu hình Rate Limiter riêng biệt: Tối đa 10 request/phút/IP để tránh lạm dụng Google STT API
const pronunciationLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 phút
  max: 10, // Giới hạn 10 requests
  message: {
    success: false,
    errorCode: 'TOO_MANY_REQUESTS',
    message: 'Con thực hành phát âm quá nhanh rồi. Hãy nghỉ một chút và thử lại nhé! 😊'
  },
  standardHeaders: true,
  legacyHeaders: false
});

/**
 * Route đánh giá phát âm tiếng Khmer
 * Endpoint: POST /api/pronunciation/check
 * Middlewares: rate limiter, multer single file ('audioFile')
 */
router.post(
  '/check',
  pronunciationLimiter,
  upload.single('audioFile'),
  checkPronunciation
);

// Áp dụng middleware xử lý lỗi đặc thù cho luồng chấm điểm phát âm
router.use(errorHandler);

module.exports = router;
