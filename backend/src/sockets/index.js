/**
 * ========================================
 * Socket.io Realtime Service
 * ========================================
 * 
 * Handles real-time events such as XP updates,
 * level-ups, rank changes, and badge unlocking.
 * Authenticates connections using JWT.
 */

const { Server } = require('socket.io');
const { verifyAccessToken } = require('../utils/token');
const { SOCKET_EVENTS } = require('../constants');
const { registerWritingHandler } = require('./writingHandler');

let ioInstance = null;

/**
 * Initialize Socket.io server
 * @param {Object} httpServer - Node HTTP server instance
 * @returns {Object} Socket.io Server instance
 */
const initSocket = (httpServer) => {
  const io = new Server(httpServer, {
    cors: {
      origin: process.env.CLIENT_URL || 'http://localhost:3000',
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
  });

  // Authentication Middleware
  io.use((socket, next) => {
    try {
      let token = socket.handshake.auth?.token || socket.handshake.headers?.authorization;

      if (!token && socket.handshake.query?.token) {
        token = socket.handshake.query.token;
      }

      if (!token) {
        console.warn('⚠️ [Socket Auth] No token provided in handshake');
        return next(new Error('Authentication error: Token not provided'));
      }

      // Handle 'Bearer <token>' format
      if (token.startsWith('Bearer ')) {
        token = token.slice(7, token.length).trim();
      }

      const tokenSnippet = token.substring(0, 12) + '...' + token.substring(token.length - 12);
      console.log(`🔌 [Socket Auth] Verifying token: ${tokenSnippet}`);

      const decoded = verifyAccessToken(token);
      socket.user = decoded; // { id, email, role }
      next();
    } catch (error) {
      console.error('❌ Socket auth failed:', error.message);
      return next(new Error('Authentication error: Invalid or expired token'));
    }
  });

  // Connection Handler
  io.on('connection', (socket) => {
    const userId = socket.user.id;
    console.log(`🔌 Realtime connection established: User ${userId} (Socket: ${socket.id})`);

    // Join user-specific room
    socket.join(userId);

    // Join general notification room
    socket.join('broadcast');

    // ── Register domain-specific handlers ──────────────────────
    registerWritingHandler(socket, io);

    // Handle ping/pong for diagnostics
    socket.on('ping', () => {
      socket.emit('pong');
    });

    // Handle disconnect
    socket.on('disconnect', () => {
      console.log(`🔌 User disconnected: User ${userId} (Socket: ${socket.id})`);
    });
  });

  ioInstance = io;
  return io;
};

/**
 * Get the active Socket.io instance
 * @returns {Object|null} Socket.io Server instance
 */
const getIO = () => {
  return ioInstance;
};

/**
 * Emit a real-time event to a specific user
 * @param {string} userId - Target user ID
 * @param {string} eventName - Socket event name from SOCKET_EVENTS
 * @param {Object} data - Payload
 */
const emitToUser = (userId, eventName, data) => {
  if (ioInstance) {
    ioInstance.to(userId.toString()).emit(eventName, data);
  } else {
    console.warn('⚠️ Socket.io instance is not initialized. Cannot emit event.');
  }
};

/**
 * Broadcast a real-time event to all connected users
 * @param {string} eventName - Socket event name
 * @param {Object} data - Payload
 */
const broadcast = (eventName, data) => {
  if (ioInstance) {
    ioInstance.emit(eventName, data);
  } else {
    console.warn('⚠️ Socket.io instance is not initialized. Cannot broadcast.');
  }
};

module.exports = {
  initSocket,
  getIO,
  emitToUser,
  broadcast,
};
