# Khmer Text-to-Speech (TTS) Provider Documentation

This document describes the design, provider choices, caching mechanics, and limitations of the dynamically generated Khmer Text-to-Speech (TTS) service implemented in the backend.

## Provider Choice
1. **Primary Provider:** **Google Cloud Text-to-Speech API**
   - **Locale:** `km-KH` (Khmer - Cambodia)
   - **Quality:** High-fidelity neural voice that reads Khmer script with correct tone, stress, and pronunciation boundaries.
   - **Activation:** Requires `GOOGLE_APPLICATION_CREDENTIALS` environment variable to be configured.

2. **Fallback Provider:** **Google Translate Public TTS API**
   - **URL Pattern:** `https://translate.google.com/translate_tts?ie=UTF-8&tl=km&client=tw-ob&q=TEXT`
   - **Why Chosen:** It is a zero-setup, unauthenticated, production-grade API that delivers high-quality neural voice recordings for Khmer. It requires no API keys, enabling seamless development and testing.

3. **Ultimate Fallback (Offline):** **Mock Audio Buffer**
   - Used in offline local development or test suites if the internet connection is disrupted, ensuring Jest tests run deterministically.

---

## Audio Caching Mechanics
To minimize round-trips to external APIs, reduce latency, and control API usage costs, all synthesized audio streams are cached.

- **Storage:** MongoDB (via Mongoose model `TtsCache`).
- **Cache Schema:**
  ```json
  {
    "text": "ក",
    "locale": "km",
    "audioBase64": "UklGRi...",
    "createdAt": "2026-06-02T16:12:27Z"
  }
  ```
- **Compound Index:** `{ text: 1, locale: 1 }` (unique) for fast lookup.
- **TTL (Time to Live) Expiration:** **30 days**.
  - Enabled via MongoDB's TTL index on the `createdAt` field using `expires: 2592000` (seconds). Documents are automatically removed by MongoDB after 30 days, forcing a re-synthesis on the next request.

---

## Known Limitations
1. **Punctuation & Ligatures:** For compound syllables or complex Khmer ligatures, the public translate TTS might occasionally read letters separately if spaces are not properly normalized.
2. **Offline Mode:** If both the device and server are completely offline, new words cannot be synthesized, though previously cached audio will play successfully from MongoDB.
