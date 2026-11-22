const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
const validateId = require('../middleware/validateId');
const c = require('../controllers/assignmentController');
const router = express.Router();

// Admin routes
router.use(authenticate, requireRole('admin'));
router.get('/patients/:id/assignments', c.listForPatient);
router.post('/patients/:id/assignments', c.create);
router.delete('/:id', validateId('id'), c.remove);
router.get('/patients/:id/completions', c.completionsForPatient);

// 👇 NEW: Admin unread notes endpoints
router.get('/admin/unread-notes', c.getUnreadNotes);
router.patch('/admin/mark-read', c.markNotesRead);

module.exports = router;