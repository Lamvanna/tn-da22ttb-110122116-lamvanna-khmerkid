/**
 * ========================================
 * Seed All Script
 * ========================================
 * 
 * Runs all seeders sequentially to prepare the database.
 */

require('dotenv').config();
const mongoose = require('mongoose');

const seedBadges = require('./seedBadges');
const seedMissions = require('./seedMissions');
const seedLessons = require('./seedLessons');

const seedAll = async () => {
  try {
    console.log('🏁 Starting complete database seeding process...');

    // Connect to MongoDB
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 10000,
    });
    console.log('✅ Connected to MongoDB.');

    // 1. Seed Badges
    await seedBadges();
    console.log('----------------------------------------');

    // 2. Seed Missions
    await seedMissions();
    console.log('----------------------------------------');

    // 3. Seed Lessons
    await seedLessons();
    console.log('----------------------------------------');

    console.log('🎉 Database seeding completed successfully! All seeders executed.');
  } catch (error) {
    console.error('❌ Database seeding failed:', error.message);
    process.exit(1);
  } finally {
    // Close MongoDB connection
    console.log('🔌 Closing MongoDB connection...');
    await mongoose.connection.close();
    console.log('👋 Database connection closed.');
    process.exit(0);
  }
};

// Execute if run directly
if (require.main === module) {
  seedAll();
}

module.exports = seedAll;
