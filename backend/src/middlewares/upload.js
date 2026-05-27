/**
 * ========================================
 * File Upload Middleware
 * ========================================
 * 
 * Multer configuration for image and audio
 * uploads to Cloudinary.
 */

const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const { cloudinary } = require('../config/cloudinary');
const { UPLOAD_CONFIG } = require('../constants');
const { AppError } = require('./errorHandler');

// ========================================
// Cloudinary Storage for Images
// ========================================
const imageStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: UPLOAD_CONFIG.IMAGE_FOLDER,
    allowed_formats: ['jpg', 'png', 'webp'],
    transformation: [{ width: 800, height: 800, crop: 'limit', quality: 'auto' }],
  },
});

// ========================================
// Cloudinary Storage for Audio
// ========================================
const audioStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: UPLOAD_CONFIG.AUDIO_FOLDER,
    resource_type: 'video', // Cloudinary treats audio as video resource type
    allowed_formats: ['mp3', 'wav'],
  },
});

// ========================================
// File Filter - Images
// ========================================
const imageFilter = (req, file, cb) => {
  if (UPLOAD_CONFIG.ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new AppError('Chỉ hỗ trợ file ảnh JPG, PNG, WebP!', 400), false);
  }
};

// ========================================
// File Filter - Audio
// ========================================
const audioFilter = (req, file, cb) => {
  if (UPLOAD_CONFIG.ALLOWED_AUDIO_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new AppError('Chỉ hỗ trợ file audio MP3, WAV!', 400), false);
  }
};

// ========================================
// Upload Middlewares
// ========================================

/**
 * Upload single image
 */
const uploadImage = multer({
  storage: imageStorage,
  fileFilter: imageFilter,
  limits: { fileSize: UPLOAD_CONFIG.MAX_IMAGE_SIZE },
}).single('image');

/**
 * Upload multiple images (max 5)
 */
const uploadImages = multer({
  storage: imageStorage,
  fileFilter: imageFilter,
  limits: { fileSize: UPLOAD_CONFIG.MAX_IMAGE_SIZE },
}).array('images', 5);

/**
 * Upload single audio file
 */
const uploadAudio = multer({
  storage: audioStorage,
  fileFilter: audioFilter,
  limits: { fileSize: UPLOAD_CONFIG.MAX_AUDIO_SIZE },
}).single('audio');

/**
 * Wrapper to handle multer errors gracefully
 * @param {Function} uploadFn - Multer upload function
 */
const handleUpload = (uploadFn) => {
  return (req, res, next) => {
    uploadFn(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return next(new AppError('File quá lớn! Vui lòng chọn file nhỏ hơn.', 400));
        }
        return next(new AppError(`Upload error: ${err.message}`, 400));
      }
      if (err) {
        return next(err);
      }
      next();
    });
  };
};

module.exports = {
  uploadImage: handleUpload(uploadImage),
  uploadImages: handleUpload(uploadImages),
  uploadAudio: handleUpload(uploadAudio),
};
