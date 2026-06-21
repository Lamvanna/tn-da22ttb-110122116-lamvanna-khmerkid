require('dotenv').config();
const mongoose = require('mongoose');
const rankService = require('../src/services/rankService');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to DB');

  const monthlyRanking = await rankService.getMonthlyRanking(20);
  console.log('\n--- MONTHLY RANKING FROM RANK SERVICE ---');
  console.log(JSON.stringify(monthlyRanking, null, 2));

  process.exit(0);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
