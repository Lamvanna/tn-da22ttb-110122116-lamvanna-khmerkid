/**
 * ========================================
 * Upload Service
 * ========================================
 * 
 * Cloudinary upload and delete operations.
 * NO automatic uploads. Only when requested.
 */

const { uploadToCloudinary, deleteFromCloudinary } = require('../config/cloudinary');
const { UPLOAD_CONFIG } = require('../constants');
const { AppError } = require('../middlewares/errorHandler');

class UploadService {
  /**
   * Handle image upload result from Multer middleware
   */
  async processImageUpload(file) {
    if (!file) {
      throw new AppError('Không tìm thấy file ảnh!', 400);
    }

    return {
      imageUrl: file.path,
      publicId: file.filename,
    };
  }

  /**
   * Handle audio upload result from Multer middleware
   */
  async processAudioUpload(file) {
    if (!file) {
      throw new AppError('Không tìm thấy file audio!', 400);
    }

    return {
      audioUrl: file.path,
      publicId: file.filename,
      duration: 0, // Duration would come from audio processing
    };
  }

  /**
   * Handle PDF upload result from Multer middleware
   */
  async processPdfUpload(file) {
    if (!file) {
      throw new AppError('Không tìm thấy file PDF!', 400);
    }

    return {
      pdfUrl: file.path,
      publicId: file.filename,
    };
  }

  /**
   * Handle Video upload result from Multer middleware
   */
  async processVideoUpload(file) {
    if (!file) {
      throw new AppError('Không tìm thấy file video!', 400);
    }

    return {
      videoUrl: file.path,
      publicId: file.filename,
    };
  }

  /**
   * Delete a file from Cloudinary
   */
  async deleteFile(publicId, resourceType = 'image') {
    if (!publicId) {
      throw new AppError('Public ID là bắt buộc!', 400);
    }

    const result = await deleteFromCloudinary(publicId, resourceType);

    if (result.result !== 'ok') {
      throw new AppError('Không thể xóa file!', 500);
    }

    return result;
  }

  /**
   * Upload image from base64
   */
  async uploadBase64Image(base64Data, folder = UPLOAD_CONFIG.IMAGE_FOLDER) {
    return await uploadToCloudinary(base64Data, {
      folder,
      resourceType: 'image',
    });
  }

  /**
   * Upload audio from base64
   */
  async uploadBase64Audio(base64Data, folder = UPLOAD_CONFIG.AUDIO_FOLDER) {
    return await uploadToCloudinary(base64Data, {
      folder,
      resourceType: 'video', // Cloudinary treats audio as video
    });
  }
}

module.exports = new UploadService();
