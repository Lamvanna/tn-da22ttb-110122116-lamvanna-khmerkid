/**
 * ========================================
 * Khmer Text Normalizer
 * ========================================
 * 
 * Cleans up Khmer text received from Google STT or inputs
 * by performing Unicode NFC normalization and removing
 * invisible formatting characters.
 */

/**
 * Chuẩn hóa chuỗi tiếng Khmer theo các tiêu chuẩn Unicode và làm sạch ký tự vô hình
 * @param {string} text - Chuỗi Khmer cần chuẩn hóa
 * @returns {string} - Chuỗi đã được chuẩn hóa
 */
function normalizeKhmerText(text) {
  // 1. Guard bảo vệ null/undefined/falsy
  if (text === null || text === undefined) {
    return "";
  }
  
  let normalized = String(text);

  // 2. Chuẩn hóa Unicode NFC (Normalization Form Canonical Composition)
  normalized = normalized.normalize('NFC');

  // Chuẩn hóa ký tự placeholder nốt tròn U+25CC (◌) thành ký tự carrier អ (U+17A2)
  // để các nguyên âm độc lập so khớp chính xác với kết quả Google STT (trả về dưới dạng អា, អិ, v.v.)
  normalized = normalized.replace(/\u25CC/g, '\u17A2');

  // Loại bỏ tiền tố "ស្រៈ" (Srak) hoặc "ស្រះ" (Srak) kèm khoảng trắng ở đầu chuỗi (nếu có)
  // để so khớp linh hoạt cho cả trường hợp đọc kèm "Srak" hay đọc mỗi âm.
  normalized = normalized.replace(/^(ស្រៈ|ស្រះ)\s*/, '');

  // 3. Xóa Zero-Width Non-Joiner (U+200C) và Zero-Width Joiner (U+200D)
  // Các ký tự này thường lẫn vào khi công cụ Speech-to-Text phân tích từ
  normalized = normalized.replace(/[\u200C\u200D]/g, '');

  // 4. Chuẩn hóa các biến thể subscript:
  // - U+17D2 (KHMER SIGN COENG) phải được GIỮ NGUYÊN vì đây là ký tự tạo chân chữ chuẩn trong tiếng Khmer
  // - Xóa bỏ Zero-Width Space (U+200B) thường lẫn vào giữa các âm tiết/phụ âm chân
  normalized = normalized.replace(/\u200B/g, '');

  // 5. Chuẩn hóa khoảng trắng: thay thế các chuỗi khoảng trắng/tab/newline bằng một khoảng trắng đơn
  normalized = normalized.replace(/\s+/g, ' ');

  // 6. Trim khoảng trắng thừa ở hai đầu chuỗi
  normalized = normalized.trim();

  return normalized;
}

module.exports = {
  normalizeKhmerText
};
