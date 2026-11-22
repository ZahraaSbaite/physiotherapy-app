const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
const validateId = require('../middleware/validateId');
const appointments = require('../controllers/appointmentController');
const assignments = require('../controllers/assignmentController');
const broadcasts = require('../controllers/broadcastController');
const channels = require('../controllers/channelController');

const router = express.Router();

// Patients only. Every query is limited to the logged-in patient.
router.use(authenticate, requireRole('patient'));

router.get('/appointments', appointments.listMine);
router.get('/appointments/:id', validateId('id'), appointments.getMine);

router.get('/assignments', assignments.listMine);
router.get('/assignments/:id', validateId('id'), assignments.getMine);
router.post('/assignments/:id/complete', validateId('id'), assignments.complete);

router.get('/completions', assignments.listMyCompletions);

router.get('/broadcasts', broadcasts.listMine);
router.post('/broadcasts/:id/read', validateId('id'), broadcasts.markRead);

router.get('/channels', channels.listMine);
router.get('/channels/:id/messages', validateId('id'), channels.listMessages);
router.post('/channels/:id/messages', validateId('id'), channels.sendMessage);
router.post('/channels/:id/read', validateId('id'), channels.markRead);

module.exports = router;
