const router = require('express').Router();
const gameProgressController = require('../controllers/gameProgressController');
const { authenticate } = require('../middlewares/auth');

// Yêu cầu xác thực tài khoản cho tất cả API tiến trình game
router.use(authenticate);

router.get('/status', gameProgressController.getStatus);
router.put('/update', gameProgressController.updateProgress);
router.get('/totals', gameProgressController.getTotals);

module.exports = router;
