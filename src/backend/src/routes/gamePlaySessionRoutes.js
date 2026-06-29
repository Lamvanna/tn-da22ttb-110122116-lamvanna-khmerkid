const router = require('express').Router();
const gamePlaySessionController = require('../controllers/gamePlaySessionController');
const { authenticate } = require('../middlewares/auth');

// Require authentication for all game play session actions
router.use(authenticate);

// POST /api/game-play-sessions - Lưu kết quả trò chơi
router.post('/', gamePlaySessionController.saveGameSession);

module.exports = router;
