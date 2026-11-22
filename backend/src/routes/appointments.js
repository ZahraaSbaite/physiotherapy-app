const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
const validateId = require('../middleware/validateId');
const c = require('../controllers/appointmentController');

const router = express.Router();

// Admins only, and only for their own patients' appointments
router.use(authenticate, requireRole('admin'));

router.get('/', c.list);
router.post('/', c.create);

router.get('/:id', validateId('id'), c.getOne);
router.patch('/:id', validateId('id'), c.update);
router.delete('/:id', validateId('id'), c.remove);

module.exports = router;
