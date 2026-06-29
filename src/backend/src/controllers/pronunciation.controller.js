/**
 * ========================================
 * Pronunciation Scoring Controller
 * ========================================
 * 
 * Handles client requests to check children's Khmer pronunciation.
 * Orchestrates validations, STT transcription, text normalization,
 * scoring, and feedback generation.
 */

const { v4: uuidv4 } = require('uuid');
const { transcribeKhmerAudio } = require('../services/speech.service');
const { calculatePronunciationScore } = require('../services/scoring.service');
const { normalizeKhmerText } = require('../utils/khmer.normalizer');
const { generateFeedback } = require('../utils/feedback.util');
const User = require('../models/User');
const missionService = require('../services/missionService');

/**
 * Đánh giá âm thanh phát âm của trẻ
 */
const checkPronunciation = async (req, res, next) => {
  const startTime = Date.now();
  const attemptId = uuidv4();
  
  // Gắn attemptId vào req làm requestId để errorHandler middleware có thể log và trả về đồng bộ
  req.requestId = attemptId;

  try {
    // ─── PIPELINE VALIDATION ──────────────────────────────────
    
    // 1. Kiểm tra req.file tồn tại?
    if (!req.file) {
      throw createValidationError('Không tìm thấy tệp tin âm thanh tải lên.', 400, 'INVALID_FORMAT');
    }

    // 2. Kiểm tra req.body.targetWord tồn tại và không rỗng?
    const { targetWord, audioDurationMs } = req.body;
    if (!targetWord || targetWord.trim() === '') {
      throw createValidationError('Thiếu từ mục tiêu để đối chiếu phát âm.', 400, 'MISSING_TARGET_WORD');
    }

    // Chuẩn hóa và làm sạch từ mục tiêu
    const normalizedTarget = normalizeKhmerText(targetWord);
    if (!normalizedTarget || normalizedTarget === "") {
      throw createValidationError('Từ mục tiêu không hợp lệ sau khi chuẩn hóa.', 400, 'MISSING_TARGET_WORD');
    }

    // Sanitize: Chỉ cho phép các ký tự Unicode Khmer chuẩn và khoảng trắng
    const khmerRegex = /^[\u1780-\u17FF\u19E0-\u19FF\s]+$/;
    if (!khmerRegex.test(normalizedTarget)) {
      throw createValidationError('Từ mục tiêu chứa ký tự không hợp lệ. Chỉ chấp nhận chữ Khmer và khoảng trắng.', 400, 'MISSING_TARGET_WORD');
    }

    // 3. Kiểm tra kích thước file >= 10KB (10240 bytes)
    const fileSize = req.file.size;
    if (fileSize < 10240) {
      throw createValidationError('Audio quá ngắn (kích thước quá nhỏ).', 400, 'SILENCE_DETECTED');
    }

    // 4. Kiểm tra thời lượng ghi âm (nếu client truyền lên) <= 30 giây (30000ms)
    if (audioDurationMs !== undefined && audioDurationMs !== null) {
      const duration = parseInt(audioDurationMs, 10);
      if (isNaN(duration) || duration < 500) {
        throw createValidationError('Thời lượng ghi âm quá ngắn (tối thiểu 0.5 giây).', 400, 'FILE_TOO_SMALL');
      }
      if (duration > 30000) {
        throw createValidationError('Thời lượng ghi âm quá dài (tối đa 30 giây).', 400, 'FILE_TOO_LARGE');
      }
    }

    // ─── SPEECH-TO-TEXT & PROCESSING ─────────────────────────

    // 5. Chuyển đổi âm thanh thành văn bản qua Google STT
    const sttResult = await transcribeKhmerAudio(req.file.buffer, normalizedTarget);

    // 6. Chuẩn hóa chuỗi kết quả nhận dạng được từ STT
    const normalizedRecognized = normalizeKhmerText(sttResult.transcript);

    // 7. Chấm điểm phát âm sử dụng Jaro-Winkler
    const scoringResult = calculatePronunciationScore(
      normalizedTarget,
      normalizedRecognized,
      sttResult.confidence,
      sttResult.isSTTEmpty
    );

    // 8. Tạo phản hồi động thân thiện với trẻ em dựa trên điểm số
    const feedback = generateFeedback(scoringResult.finalScore, sttResult.isSTTEmpty);

    // ─── LATENCY & LOGGING ────────────────────────────────────
    const latencyMs = Date.now() - startTime;
    const fileSizeKB = Math.round((fileSize / 1024) * 10) / 10;
    const transcriptLength = normalizedRecognized.length;

    // Log chi tiết cho từng nỗ lực luyện nói của trẻ
    console.log(`🎙️ [PRONUNCIATION] Attempt: ${attemptId} | targetWord: "${normalizedTarget}" | fileSize: ${fileSizeKB}KB | transcriptLength: ${transcriptLength} | finalScore: ${scoringResult.finalScore} | latency: ${latencyMs}ms`);

    // Cảnh báo nếu latency vượt ngưỡng mục tiêu 4 giây
    if (latencyMs > 4000) {
      console.warn(`⚠️ [PRONUNCIATION WARNING] Latency vượt ngưỡng mục tiêu: ${latencyMs}ms (attemptId: ${attemptId})`);
    }

    // ─── SUCCESS RESPONSE ─────────────────────────────────────
    // Tăng counter phát âm thành công (cho badge) nếu user đăng nhập
    if (req.user && scoringResult.isCorrect) {
      try {
        await User.findByIdAndUpdate(req.user._id, {
          $inc: { 'learningProgress.speakingSuccessCount': 1 }
        });
        // Update mission progress for speaking
        await missionService.updateProgress(req.user._id, 'speak_lesson');
      } catch (e) {
        console.warn(`⚠️ [PRONUNCIATION] Failed to increment speaking counter: ${e.message}`);
      }
    }

    return res.status(200).json({
      success: true,
      attemptId,
      targetWord: normalizedTarget,
      recognizedText: normalizedRecognized,
      isSTTEmpty: sttResult.isSTTEmpty,
      confidence: sttResult.confidence,
      similarityPercentage: scoringResult.similarityPercentage,
      finalScore: scoringResult.finalScore,
      isCorrect: scoringResult.isCorrect,
      feedback,
      scoringMethod: scoringResult.scoringMethod,
      processedAt: new Date().toISOString()
    });

  } catch (error) {
    // Chuyển tiếp lỗi đến global error handler middleware
    next(error);
  }
};

/**
 * Hàm hỗ trợ tạo đối tượng lỗi kèm mã trạng thái HTTP và mã lỗi chuẩn
 */
function createValidationError(message, statusCode, errorCode) {
  const err = new Error(message);
  err.statusCode = statusCode;
  err.code = errorCode;
  return err;
}

module.exports = {
  checkPronunciation
};
