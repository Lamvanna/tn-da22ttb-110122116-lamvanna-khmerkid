/**
 * ========================================
 * Centralized Error Handler Middleware
 * ========================================
 * 
 * Standardizes error responses with friendly messages
 * and unique request IDs for debugging.
 */

const { v4: uuidv4 } = require('uuid');

const errorHandler = (err, req, res, next) => {
  // Tạo hoặc sử dụng requestId đã có từ request để dễ dàng tra cứu log
  const requestId = req.requestId || err.requestId || uuidv4();
  
  let statusCode = err.statusCode || 500;
  let errorCode = err.code || 'INTERNAL_ERROR';
  let message = err.message || 'Đã xảy ra lỗi hệ thống không xác định. Con hãy thử lại nhé!';

  // 1. Xử lý lỗi từ Multer (VD: quá giới hạn dung lượng)
  if (err.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      statusCode = 413;
      errorCode = 'FILE_TOO_LARGE';
      message = 'File âm thanh quá lớn (tối đa 3MB).';
    } else {
      statusCode = 400;
      errorCode = 'INVALID_FORMAT';
      message = 'Tệp tin tải lên không hợp lệ hoặc sai định dạng WAV/PCM.';
    }
  }

  // 2. Xử lý các lỗi chuyên biệt do hệ thống ném ra
  if (message === 'STT_TIMEOUT') {
    statusCode = 504;
    errorCode = 'STT_TIMEOUT';
    message = 'Máy chủ nhận dạng giọng nói phản hồi quá lâu. Con hãy nói lại nhé!';
  } else if (message === 'SILENCE_DETECTED') {
    statusCode = 400;
    errorCode = 'SILENCE_DETECTED';
    message = 'Con chưa nói gì — hãy thử lại nhé!';
  } else if (message === 'FILE_TOO_SMALL') {
    statusCode = 400;
    errorCode = 'FILE_TOO_SMALL';
    message = 'Audio quá ngắn — hãy nói rõ hơn nhé!';
  } else if (message === 'MISSING_TARGET_WORD') {
    statusCode = 400;
    errorCode = 'MISSING_TARGET_WORD';
    message = 'Không tìm thấy từ cần phát âm mẫu.';
  } else if (message === 'STT_ERROR') {
    statusCode = 500;
    errorCode = 'STT_ERROR';
    message = 'Lỗi dịch vụ chuyển đổi giọng nói.';
  }

  // 3. Log chi tiết lỗi trên server để nhà phát triển theo dõi
  console.error(`❌ [Error - Request ID: ${requestId}]`);
  console.error(`   Status Code: ${statusCode}`);
  console.error(`   Error Code : ${errorCode}`);
  console.error(`   Message    : ${err.message || message}`);
  if (statusCode === 500) {
    console.error(`   Stack      : ${err.stack}`);
  }

  // 4. Trả về phản hồi JSON theo định dạng chuẩn
  res.status(statusCode).json({
    success: false,
    errorCode,
    message,
    requestId
  });
};

module.exports = errorHandler;
