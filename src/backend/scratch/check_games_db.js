const mongoose = require('mongoose');
require('dotenv').config({ path: '../.env' });

const gameResultSchema = new mongoose.Schema({}, { strict: false });
const GameResult = mongoose.model('GameResult', gameResultSchema, 'gameresults');

const gamePlaySessionSchema = new mongoose.Schema({}, { strict: false });
const GamePlaySession = mongoose.model('GamePlaySession', gamePlaySessionSchema, 'gameplaysessions');

const gameProgressSchema = new mongoose.Schema({}, { strict: false });
const GameProgress = mongoose.model('GameProgress', gameProgressSchema, 'gameprogresses');

const gameQuestionSchema = new mongoose.Schema({}, { strict: false });
const GameQuestion = mongoose.model('GameQuestion', gameQuestionSchema, 'gamequestions');

async function main() {
  const uri = process.env.MONGO_URI || "mongodb+srv://admin:PCO6NePc2Gmcifzt@lamv.tzc1slv.mongodb.net/khmerkid";
  console.log('Connecting to database...');
  await mongoose.connect(uri);
  console.log('Connected!');

  const questionCount = await GameQuestion.countDocuments();
  console.log(`\nTotal GameQuestion records: ${questionCount}`);

  const targetQuestion = await GameQuestion.findOne({ prompt: /khó chịu/i });
  console.log('\nFound Target Question for "khó chịu":');
  console.log(JSON.stringify(targetQuestion, null, 2));

  if (questionCount > 0) {
    const questions = await GameQuestion.find().limit(5);
    console.log('\nSample GameQuestion records:');
    console.log(JSON.stringify(questions, null, 2));

    const uniqueKeys = await GameQuestion.distinct('gameKey');
    console.log(`\nUnique gameKeys in GameQuestion:`, uniqueKeys);
  }

  const resultCount = await GameResult.countDocuments();
  console.log(`Total GameResult records: ${resultCount}`);

  if (resultCount > 0) {
    const results = await GameResult.find().limit(5);
    console.log('\nSample GameResult records:');
    console.log(JSON.stringify(results, null, 2));

    const uniqueGameTypes = await GameResult.distinct('gameType');
    console.log(`\nUnique game types in GameResult:`, uniqueGameTypes);
  }

  const sessionCount = await GamePlaySession.countDocuments();
  console.log(`\nTotal GamePlaySession records: ${sessionCount}`);
  if (sessionCount > 0) {
    const sessions = await GamePlaySession.find().limit(5);
    console.log('\nSample GamePlaySession records:');
    console.log(JSON.stringify(sessions, null, 2));
  }

  const progressCount = await GameProgress.countDocuments();
  console.log(`\nTotal GameProgress records: ${progressCount}`);
  if (progressCount > 0) {
    const progresses = await GameProgress.find().limit(5);
    console.log('\nSample GameProgress records:');
    console.log(JSON.stringify(progresses, null, 2));
  }

  await mongoose.disconnect();
}

main().catch(console.error);
