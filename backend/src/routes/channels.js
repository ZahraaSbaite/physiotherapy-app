const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
const validateId = require('../middleware/validateId');
const c = require('../controllers/channelController');

const router = express.Router();

router.use(authenticate, requireRole('admin'));

router.get('/', c.list);
router.post('/', c.create);
router.get('/:id', validateId('id'), c.getOne);
router.patch('/:id', validateId('id'), c.update);

router.get('/:id/messages', validateId('id'), c.listMessages);
router.post('/:id/messages', validateId('id'), c.sendMessage);
router.delete('/:id/messages/:messageId', validateId('id', 'messageId'), c.removeMessage);
router.post('/:id/read', validateId('id'), c.markRead);

module.exports = router;
