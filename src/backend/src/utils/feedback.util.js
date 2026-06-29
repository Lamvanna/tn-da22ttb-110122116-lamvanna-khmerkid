/**
 * ========================================
 * Pronunciation Feedback Generator
 * ========================================
 * 
 * Generates encouraging, kid-friendly Vietnamese feedback
 * based on pronunciation scores and STT completeness.
 */

/**
 * Sinh phản hồi thân thiện dựa trên điểm số và trạng thái STT
 * @param {number} score - Điểm số cuối cùng của trẻ (0 - 100)
 * @param {boolean} isSTTEmpty - Trạng thái rỗng của Speech-to-Text
 * @returns {string} - Chuỗi phản hồi động kèm emoji trực quan
 */
function generateFeedback(score, isSTTEmpty) {
  // 1. Ưu tiên xử lý trường hợp Google STT không nhận dạng được gì
  if (isSTTEmpty === true) {
    return "Con hãy nói to hơn một chút nhé! Máy chưa nghe thấy giọng con.";
  }

  // 2. Phân loại phản hồi dựa trên thang điểm 0 - 100
  if (score >= 90) {
    return "Tuyệt vời! Con phát âm rất chính xác! 🌟";
  } else if (score >= 80) {
    return "Giỏi lắm! Con phát âm gần đúng rồi! 👏";
  } else if (score >= 65) {
    return "Tốt lắm! Hãy đọc rõ hơn một chút nữa nhé! 💪";
  } else if (score >= 40) {
    return "Con đang tiến bộ đó! Hãy thử lại nhé! 😊";
  } else {
    return "Không sao đâu! Hãy nghe lại mẫu và thử thêm nhé! 🎵";
  }
}

module.exports = {
  generateFeedback
};
