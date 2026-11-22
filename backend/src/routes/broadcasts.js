const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
const validateId = require('../middleware/validateId');
const c = require('../controllers/broadcastController');
const router = express.Router();

router.use(authenticate, requireRole('admin'));
router.get('/', c.list);
router.post('/', c.create);
router.patch('/:id', validateId('id'), c.update); // 👈 ADDED
router.get('/:id', validateId('id'), c.getOne);
router.delete('/:id', validateId('id'), c.remove);

module.exports = router;