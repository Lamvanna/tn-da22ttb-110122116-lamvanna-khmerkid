require('dotenv').config({ path: '../.env' });
const mongoose = require('mongoose');
const LibraryItem = require('../src/models/LibraryItem');

async function main() {
  try {
    const mongoUri = process.env.MONGO_URI || 'mongodb+srv://admin:PCO6NePc2Gmcifzt@lamv.tzc1slv.mongodb.net/khmerkid';
    console.log('Connecting to MongoDB:', mongoUri);
    await mongoose.connect(mongoUri);
    console.log('Connected!');

    const items = await LibraryItem.find({});
    console.log(`Found ${items.length} library items:`);
    items.forEach((item, index) => {
      console.log(`${index + 1}. [${item.type}] ${item.title} (${item.isActive ? 'Active' : 'Inactive'})`);
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.connection.close();
    console.log('Connection closed.');
  }
}

main();
