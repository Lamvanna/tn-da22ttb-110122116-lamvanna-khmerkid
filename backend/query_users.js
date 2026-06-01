const mongoose = require('mongoose');
require('dotenv').config();

const userSchema = new mongoose.Schema({}, { strict: false });
const User = mongoose.model('User', userSchema, 'users');

async function run() {
  const uri = process.env.MONGO_URI || "mongodb+srv://admin:PCO6NePc2Gmcifzt@lamv.tzc1slv.mongodb.net/khmerkid";
  console.log('Connecting to MongoDB...');
  await mongoose.connect(uri);
  console.log('Connected!');

  const count = await User.countDocuments();
  console.log(`Total users in DB: ${count}`);

  const users = await User.find({}).limit(50).lean();
  console.log('Users list:', JSON.stringify(users, null, 2));

  await mongoose.disconnect();
  console.log('Disconnected!');
}

run().catch(console.error);


