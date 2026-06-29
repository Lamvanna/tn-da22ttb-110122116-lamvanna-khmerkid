/**
 * ========================================
 * Jest Unit Tests - khmer.normalizer
 * ========================================
 */

const { normalizeKhmerText } = require('../src/utils/khmer.normalizer');

describe('Khmer Text Normalizer Tests', () => {
  // Case 1: Chuỗi rỗng hoặc null/undefined
  test('handles null, undefined, and empty strings', () => {
    expect(normalizeKhmerText(null)).toBe('');
    expect(normalizeKhmerText(undefined)).toBe('');
    expect(normalizeKhmerText('')).toBe('');
  });

  // Case 2: Chuỗi chỉ có khoảng trắng
  test('handles whitespace-only strings', () => {
    expect(normalizeKhmerText('   ')).toBe('');
    expect(normalizeKhmerText('\t\n')).toBe('');
  });

  // Case 3: Chuỗi có ZWJ / ZWNJ / ZWSP
  test('removes ZWJ, ZWNJ, and ZWSP but preserves valid Khmer text', () => {
    // U+200B là ZWSP, U+200C là ZWNJ, U+200D là ZWJ
    const inputWithZW = 'សួ\u200Bស\u200C្តី\u200D';
    const expected = 'សួស្តី'; // Ký tự được giữ sạch
    expect(normalizeKhmerText(inputWithZW)).toBe(expected);
  });

  // Case 4: Chuỗi Khmer hợp lệ thông thường và chuẩn hóa khoảng trắng
  test('normalizes spaces and trims valid Khmer text', () => {
    const input = '   ភាសា   ខ្មែរ   ';
    const expected = 'ភាសា ខ្មែរ';
    expect(normalizeKhmerText(input)).toBe(expected);
  });

  // Case 5: Giữ nguyên chân chữ Khmer (Khmer Sign Coeng U+17D2)
  test('preserves Khmer Sign Coeng (subscripts)', () => {
    // Coeng sign là U+17D2. Ví dụ: 'ខ្មែរ' (Khmer) có Coeng (U+17D2) dưới phụ âm 'ម' (U+179Map)
    const word = 'ខ្មែរ'; // [U+1781, U+17D2, U+1798, U+17C2, U+179Empty]
    expect(normalizeKhmerText(word)).toBe(word);
  });

  // Case 6: Chuẩn hóa nốt tròn U+25CC (◌) thành ký tự carrier អ (U+17A2)
  test('normalizes dotted circle placeholder U+25CC to vowel carrier U+17A2', () => {
    expect(normalizeKhmerText('◌ា')).toBe('អា');
    expect(normalizeKhmerText('◌ិ')).toBe('អិ');
  });

  // Case 7: Loại bỏ tiền tố "ស្រៈ" hoặc "ស្រះ" ở đầu chuỗi
  test('strips ស្រៈ or ស្រះ prefix with optional spaces', () => {
    expect(normalizeKhmerText('ស្រៈអា')).toBe('អា');
    expect(normalizeKhmerText('ស្រះអា')).toBe('អា');
    expect(normalizeKhmerText('ស្រៈ អា')).toBe('អា');
    expect(normalizeKhmerText('ស្រះ ◌ា')).toBe('អា');
  });
});
