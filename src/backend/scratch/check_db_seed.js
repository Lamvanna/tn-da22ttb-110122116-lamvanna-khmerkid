/**
 * Script to check count of seeded data in MongoDB collections
 */
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

async function checkSeed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');

  const models = [
    { name: 'User', model: require('../src/models/User') },
    { name: 'Progress', model: require('../src/models/Progress') },
    { name: 'Lesson', model: require('../src/models/Lesson') },
    { name: 'Badge', model: require('../src/models/Badge') },
    { name: 'Mission', model: require('../src/models/Mission') },
    { name: 'LibraryItem', model: require('../src/models/LibraryItem') },
    { name: 'StandardCharacter', model: require('../src/models/StandardCharacter') },
  ];

  console.log('\n--- COLLECTION COUNTS ---');
  for (const m of models) {
    try {
      const count = await m.model.countDocuments({});
      console.log(`${m.name}: ${count} documents`);
    } catch (e) {
      console.log(`${m.name}: Error - ${e.message}`);
    }
  }

  await mongoose.disconnect();
}

checkSeed().catch(err => {
  console.error(err);
  process.exit(1);
});
