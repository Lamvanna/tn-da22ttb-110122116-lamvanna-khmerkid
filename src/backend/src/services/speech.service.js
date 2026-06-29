/**
 * ========================================
 * Google Cloud Speech-to-Text Service
 * ========================================
 * 
 * Interacts with Google Cloud Speech API to transcribe
 * Khmer audio buffer in-memory.
 */

const speech = require('@google-cloud/speech');

const hasCredentials = !!process.env.GOOGLE_APPLICATION_CREDENTIALS;
let speechClient = null;

if (hasCredentials) {
  try {
    speechClient = new speech.SpeechClient();
  } catch (err) {
    console.error('⚠️ [SpeechService] Lỗi khởi tạo Google STT client:', err.message);
  }
} else {
  console.warn('⚠️ [SpeechService] Không tìm thấy biến môi trường GOOGLE_APPLICATION_CREDENTIALS.');
  console.warn('⚠️ [SpeechService] Sử dụng Simulated Speech-to-Text Service cho chế độ phát triển/kiểm thử.');
}

/**
 * Kiểm tra xem buffer âm thanh PCM 16-bit (WAV) có bị im lặng (silent) hay không.
 * Tính toán giá trị biên độ trung bình bình phương (RMS) của các mẫu âm thanh.
 * @param {Buffer} buffer - Buffer âm thanh
 * @param {number} threshold - Ngưỡng biên độ để coi là im lặng
 * @returns {boolean} - true nếu im lặng
 */
function isBufferSilent(buffer, threshold = 1000) {
  if (!buffer || buffer.length < 44) return true;

  let totalSquare = 0;
  let sampleCount = 0;

  // Đọc mỗi mẫu 2 byte (Int16) bỏ qua header WAV 44 byte
  for (let i = 44; i < buffer.length - 1; i += 2) {
    const sample = buffer.readInt16LE(i);
    totalSquare += sample * sample;
    sampleCount++;
  }

  if (sampleCount === 0) return true;

  const rms = Math.sqrt(totalSquare / sampleCount);
  console.log(`🎙️ [SpeechService] [RMS Check] Amplitude: ${rms.toFixed(1)} (Silence Threshold: ${threshold})`);
  return rms < threshold;
}

/**
 * Thực hiện nhận dạng giọng nói Khmer từ audio buffer
 * @param {Buffer} audioBuffer - Buffer chứa dữ liệu âm thanh ghi được từ client
 * @param {string} targetWord - Từ mục tiêu dùng để giả lập khi thiếu API Credentials
 * @returns {Promise<object>} - Trả về transcript, confidence và cờ isSTTEmpty
 */
async function transcribeKhmerAudio(audioBuffer, targetWord = "") {
  const silent = isBufferSilent(audioBuffer, 1000);

  // Nếu không có credentials, trả về kết quả giả lập (Mock) để phát triển và kiểm thử dễ dàng
  if (!speechClient) {
    // Giả lập độ trễ mạng từ 600ms đến 1200ms
    await new Promise(resolve => setTimeout(resolve, 600 + Math.random() * 600));

    if (silent) {
      console.log(`🎙️ [SpeechService] [SIMULATED] targetWord: "${targetWord}" -> [IM LẶNG / CHƯA NÓI] -> transcript: ""`);
      return {
        transcript: "",
        confidence: 0.0,
        isSTTEmpty: true
      };
    }

    const isMockCorrect = Math.random() > 0.05; // 95% cơ hội phát âm thành công
    const transcript = isMockCorrect ? targetWord : "";
    const confidence = isMockCorrect ? (0.75 + Math.random() * 0.2) : 0.0;

    console.log(`🎙️ [SpeechService] [SIMULATED] targetWord: "${targetWord}" -> transcript: "${transcript}" | confidence: ${confidence.toFixed(2)}`);

    return {
      transcript,
      confidence,
      isSTTEmpty: transcript === ""
    };
  }

  // 1. Cấu hình request gửi đến Google Speech API
  const request = {
    audio: {
      content: audioBuffer.toString('base64'),
    },
    config: {
      encoding: 'LINEAR16',
      sampleRateHertz: 16000,
      languageCode: 'km-KH',
      audioChannelCount: 1,
      enableAutomaticPunctuation: false,
      model: 'default', // km-KH hiện tại chưa có enhanced model riêng biệt
    },
  };

  try {
    // 2. Bao bọc API call trong một Timeout Wrapper 10 giây
    const sttCall = speechClient.recognize(request);
    
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('STT_TIMEOUT')), 10000);
    });

    // Chạy đua giữa Google API call và Timeout 10 giây
    const [response] = await Promise.race([sttCall, timeoutPromise]);

    // 3. Xử lý kết quả trả về
    // Trường hợp 1: Kết quả trả về rỗng hoặc undefined (Google không phát hiện ra giọng nói)
    if (!response || !response.results || response.results.length === 0) {
      return {
        transcript: "",
        confidence: 0.0,
        isSTTEmpty: true
      };
    }

    // Lấy phương án nhận dạng đầu tiên tốt nhất (alternatives[0])
    const alternative = response.results[0].alternatives[0];
    if (!alternative) {
      return {
        transcript: "",
        confidence: 0.0,
        isSTTEmpty: true
      };
    }

    const transcript = alternative.transcript ? alternative.transcript.trim() : "";
    let confidence = alternative.confidence;

    // Trường hợp đặc biệt: Google đôi khi bỏ qua confidence khi transcript quá ngắn hoặc đặc trưng Khmer
    if (confidence === undefined || confidence === null) {
      console.warn(`⚠️ [SpeechService] Google STT trả về transcript "${transcript}" nhưng confidence bị undefined. Sử dụng giá trị fallback: 0.5`);
      confidence = 0.5;
    }

    return {
      transcript,
      confidence,
      isSTTEmpty: transcript === ""
    };

  } catch (error) {
    // Nếu là lỗi timeout thì ném lỗi STT_TIMEOUT để errorHandler middleware xử lý đúng mã lỗi
    if (error.message === 'STT_TIMEOUT') {
      throw error;
    }
    
    // Ghi nhận lỗi và chuyển tiếp dưới tên STT_ERROR
    console.error('❌ [SpeechService] Lỗi kết nối Google STT API:', error);
    throw new Error('STT_ERROR');
  }
}

module.exports = {
  transcribeKhmerAudio
};
