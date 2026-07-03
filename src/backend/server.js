/**
 * ========================================
 * KhmerKid Backend - Main Server
 * ========================================
 * 
 * Express.js server with MongoDB, Socket.io,
 * JWT Auth, Google OAuth, Cloudinary integration.
 * 
 * @author KhmerKid Team
 * @version 1.0.0
 */

require('dotenv').config();

const fs = require('fs');
const path = require('path');

// Dynamically fix GOOGLE_APPLICATION_CREDENTIALS for local vs cloud deployment
const candidateCredentialsPaths = [
  path.join(__dirname, 'google-key.json'),
  '/etc/secrets/google-key.json',
  './google-key.json',
  '/opt/render/project/src/google-key.json',
  '/opt/render/project/src/src/backend/google-key.json'
];

for (const p of candidateCredentialsPaths) {
  if (fs.existsSync(p)) {
    process.env.GOOGLE_APPLICATION_CREDENTIALS = p;
    console.log(`🔑 [Google Credentials] Dynamically set to: ${p}`);
    break;
  }
}

const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const cookieParser = require('cookie-parser');
const passport = require('passport');

// Config imports
const connectDB = require('./src/config/database');
const { initSocket } = require('./src/sockets');
const { initStudyReminderCron } = require('./src/cron/studyReminderCron');

// Route imports
const routes = require('./src/routes');

// Middleware imports
const { globalErrorHandler, AppError } = require('./src/middlewares/errorHandler');
const { generalLimiter } = require('./src/middlewares/rateLimiter');

// ========================================
// Initialize Express App
// ========================================
const app = express();
const server = http.createServer(app);

// ========================================
// Connect to MongoDB
// ========================================
connectDB();

// ========================================
// Initialize Socket.io
// ========================================
const io = initSocket(server);
app.set('io', io); // Make io accessible in routes/controllers

// Initialize Cron Schedulers
initStudyReminderCron();

// ========================================
// Global Middlewares
// ========================================

// Security headers
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.CLIENT_URL || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Request logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Body parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Cookie parser
app.use(cookieParser());

// Rate limiting
app.use('/api/', generalLimiter);

// Passport initialization
require('./src/config/passport');
app.use(passport.initialize());

// ========================================
// API Routes
// ========================================

// Health check
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'KhmerKid API is running! 🚀',
    data: {
      version: '1.0.0',
      environment: process.env.NODE_ENV,
      timestamp: new Date().toISOString(),
    },
  });
});

// Mount all routes
app.use('/api', routes);

// ========================================
// Error Handling
// ========================================

// Handle 404 - Route not found
app.all('*', (req, res, next) => {
  next(new AppError(`Route ${req.originalUrl} not found`, 404));
});

// Global error handler
app.use(globalErrorHandler);

// ========================================
// Start Server
// ========================================
const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log('');
  console.log('╔════════════════════════════════════════╗');
  console.log('║     🎓 KhmerKid Backend Server 🎓     ║');
  console.log('╠════════════════════════════════════════╣');
  console.log(`║  🌍 Environment: ${(process.env.NODE_ENV || 'development').padEnd(19)} ║`);
  console.log(`║  🚀 Port:        ${String(PORT).padEnd(19)} ║`);
  console.log(`║  📡 API:         /api                  ║`);
  console.log(`║  ❤️  Health:      /api/health            ║`);
  console.log('╚════════════════════════════════════════╝');
  console.log('');
});

// ========================================
// Graceful Shutdown
// ========================================
process.on('SIGTERM', () => {
  console.log('🔄 SIGTERM received. Shutting down gracefully...');
  server.close(() => {
    console.log('💤 Process terminated.');
    process.exit(0);
  });
});

process.on('unhandledRejection', (err) => {
  console.error('❌ Unhandled Rejection:', err.message);
  server.close(() => {
    process.exit(1);
  });
});

module.exports = { app, server };
