const express = require('express');
const { authenticate } = require('../middleware/auth');
const c = require('../controllers/authController');

const router = express.Router();

router.post('/login', c.login); // public

router.use(authenticate); // everything below needs a login

router.get('/me', c.me);
router.patch('/me', c.updateMe);
router.post('/change-password', c.changePassword);
router.put('/fcm-token', c.saveFcmToken);
router.post('/logout', c.logout);

module.exports = router;