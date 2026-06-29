/**
 * ========================================
 * Test Routes
 * ========================================
 */

const router = require('express').Router();
const { authenticate } = require('../middlewares/auth');
const testController = require('../controllers/testController');

router.use(authenticate);
router.get('/questions', testController.getQuestions);

module.exports = router;
