/**
 * ========================================
 * Multer Audio Upload Middleware
 * ========================================
 * 
 * Configures multer for in-memory audio storage
 * with size and format restrictions.
 */

const multer = require('multer');

// Cấu hình lưu trữ bộ nhớ (in-memory buffer) để tránh ghi tệp ra đĩa cứng
const storage = multer.memoryStorage();

// Bộ lọc tệp: chỉ cho phép tệp âm thanh định dạng WAV hoặc PCM
const fileFilter = (req, file, cb) => {
  const allowedMimes = [
    'audio/wav',
    'audio/x-wav',
    'audio/pcm',
    'audio/wave',
    'audio/x-pn-wav',
    'audio/L16'
  ];

  const extension = file.originalname.split('.').pop().toLowerCase();
  
  if (allowedMimes.includes(file.mimetype) || ['wav', 'pcm'].includes(extension)) {
    cb(null, true);
  } else {
    // Trả về lỗi định dạng tệp không được hỗ trợ
    const err = new Error('Chỉ chấp nhận định dạng âm thanh WAV hoặc PCM (INVALID_FORMAT)');
    err.code = 'INVALID_FORMAT';
    cb(err, false);
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 3 * 1024 * 1024 // Giới hạn kích thước tối đa 3MB
  },
  fileFilter: fileFilter
});

module.exports = upload;
