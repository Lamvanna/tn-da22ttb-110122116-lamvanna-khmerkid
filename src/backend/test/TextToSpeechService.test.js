/**
 * ========================================
 * Jest Unit Tests - TextToSpeechService
 * ========================================
 */

const TextToSpeechService = require('../src/services/TextToSpeechService');
const TtsCache = require('../src/models/TtsCache');

// Mock Mongoose model to avoid real database connection in unit tests
jest.mock('../src/models/TtsCache');

describe('TextToSpeechService Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('synthesize returns audio buffer', async () => {
    TtsCache.findOne.mockResolvedValue(null);
    TtsCache.findOneAndUpdate.mockResolvedValue({});

    const buffer = await TextToSpeechService.synthesize('ក', 'km');
    expect(Buffer.isBuffer(buffer)).toBe(true);
    expect(buffer.length).toBeGreaterThan(0);
  });

  test('cache hit returns cached base64 audio result as buffer', async () => {
    const mockBase64 = Buffer.from('mocked_audio_content').toString('base64');
    TtsCache.findOne.mockResolvedValue({
      text: 'ក',
      locale: 'km',
      audioBase64: mockBase64
    });

    const buffer = await TextToSpeechService.synthesize('ក', 'km');
    expect(Buffer.isBuffer(buffer)).toBe(true);
    expect(buffer.toString()).toBe('mocked_audio_content');
    // Ensure findOne was queried, and findOneAndUpdate was NOT called (cache hit)
    expect(TtsCache.findOne).toHaveBeenCalledWith({ text: 'ក', locale: 'km' });
    expect(TtsCache.findOneAndUpdate).not.toHaveBeenCalled();
  });

  test('unsupported locale falls back gracefully', async () => {
    TtsCache.findOne.mockResolvedValue(null);
    TtsCache.findOneAndUpdate.mockResolvedValue({});

    // Using an arbitrary unsupported locale, should fall back to translate_tts or mock
    const buffer = await TextToSpeechService.synthesize('hello', 'xyz');
    expect(Buffer.isBuffer(buffer)).toBe(true);
    expect(buffer.length).toBeGreaterThan(0);
  });
});
