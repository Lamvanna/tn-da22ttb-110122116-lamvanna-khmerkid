'use strict';

const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables
dotenv.config({ path: path.join(__dirname, '../.env') });

const StandardCharacter = require('../src/models/StandardCharacter');

function getBoundingBox(points) {
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  for (const p of points) {
    if (p.x < minX) minX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.x > maxX) maxX = p.x;
    if (p.y > maxY) maxY = p.y;
  }
  return {
    width: maxX - minX,
    height: maxY - minY,
  };
}

async function analyzeDb() {
  try {
    const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/khmerkid';
    console.log('Connecting to Mongo:', mongoUri);
    await mongoose.connect(mongoUri);
    console.log('Connected!');

    const docs = await StandardCharacter.find({ isActive: true }).lean();
    console.log(`Analyzing ${docs.length} active characters...`);

    const results = [];

    for (const doc of docs) {
      if (!doc.standardStrokes || doc.standardStrokes.length === 0) continue;
      
      const allPoints = doc.standardStrokes.flat();
      if (allPoints.length === 0) continue;

      const bb = getBoundingBox(allPoints);
      const ratio = bb.height > 0 ? (bb.width / bb.height) : 0;
      results.push({
        character: doc.character,
        type: doc.type,
        width: bb.width,
        height: bb.height,
        ratio: ratio
      });
    }

    // Sort by ratio descending (widest first)
    results.sort((a, b) => b.ratio - a.ratio);

    console.log('\nTop 15 WIDEST characters (highest width/height):');
    for (let i = 0; i < Math.min(15, results.length); i++) {
      const r = results[i];
      console.log(`${i+1}. "${r.character}" (${r.type}) | Ratio: ${r.ratio.toFixed(3)} | W: ${r.width.toFixed(1)} | H: ${r.height.toFixed(1)}`);
    }

    // Sort by ratio ascending (tallest first)
    results.sort((a, b) => a.ratio - b.ratio);

    console.log('\nTop 15 TALLEST characters (lowest width/height):');
    for (let i = 0; i < Math.min(15, results.length); i++) {
      const r = results[i];
      console.log(`${i+1}. "${r.character}" (${r.type}) | Ratio: ${r.ratio.toFixed(3)} | W: ${r.width.toFixed(1)} | H: ${r.height.toFixed(1)}`);
    }

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected!');
  }
}

analyzeDb();
