const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
const validateId = require('../middleware/validateId');
const c = require('../controllers/assignmentController');

const router = express.Router();

router.use(authenticate, requireRole('admin'));

router.delete('/:id', validateId('id'), c.remove);

module.exports = router;
