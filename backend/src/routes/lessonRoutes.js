/**
 * ========================================
 * Lesson Routes
 * ========================================
 * 
 * GET    /api/lessons
 * GET    /api/lessons/:id
 * GET    /api/lessons/type/:type
 * POST   /api/lessons        (admin)
 * PUT    /api/lessons/:id    (admin)
 * DELETE /api/lessons/:id    (admin)
 */

const router = require('express').Router();
const lessonController = require('../controllers/lessonController');
const { authenticate } = require('../middlewares/auth');
const { authorize } = require('../middlewares/role');
const { validate } = require('../middlewares/validate');
const { createLessonValidator, updateLessonValidator, idParamValidator } = require('../validators');

router.use(authenticate);

// User routes
router.get('/', lessonController.getLessons);
router.get('/type/:type', lessonController.getLessonsByType);
router.get('/:id', idParamValidator, validate, lessonController.getLessonById);

// Admin routes
router.post('/', authorize('admin'), createLessonValidator, validate, lessonController.createLesson);
router.put('/:id', authorize('admin'), idParamValidator, updateLessonValidator, validate, lessonController.updateLesson);
router.delete('/:id', authorize('admin'), idParamValidator, validate, lessonController.deleteLesson);

module.exports = router;
