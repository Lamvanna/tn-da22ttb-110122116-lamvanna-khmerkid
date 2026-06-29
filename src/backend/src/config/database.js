/**
 * ========================================
 * Database Configuration - MongoDB
 * ========================================
 * 
 * Mongoose connection with retry logic,
 * connection events, and graceful handling.
 */

const mongoose = require('mongoose');

/**
 * Connect to MongoDB with retry logic
 * @param {number} retries - Number of retry attempts
 */
const connectDB = async (retries = 5) => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      // Mongoose 8 defaults are good, but we set these explicitly
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    console.log(`📦 Database: ${conn.connection.name}`);

  } catch (error) {
    console.error(`❌ MongoDB Connection Error: ${error.message}`);
    
    if (retries > 0) {
      console.log(`🔄 Retrying connection... (${retries} attempts left)`);
      await new Promise(resolve => setTimeout(resolve, 5000));
      return connectDB(retries - 1);
    }
    
    console.error('💀 Failed to connect to MongoDB after multiple attempts');
    process.exit(1);
  }
};

// ========================================
// Connection Events
// ========================================

mongoose.connection.on('connected', () => {
  console.log('📡 Mongoose connected to MongoDB');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ Mongoose connection error:', err.message);
});

mongoose.connection.on('disconnected', () => {
  console.log('🔌 Mongoose disconnected from MongoDB');
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  console.log('💤 MongoDB connection closed through app termination');
  process.exit(0);
});

module.exports = connectDB;
