const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
const validateId = require('../middleware/validateId');
const c = require('../controllers/patientController');
const a = require('../controllers/assignmentController');

const router = express.Router();

// Everything here is for admins only, and only for their own patients
router.use(authenticate, requireRole('admin'));

router.get('/', c.list);
router.post('/', c.create);

router.get('/:id', validateId('id'), c.getOne);
router.patch('/:id', validateId('id'), c.update);
router.delete('/:id', validateId('id'), c.remove);

router.post('/:id/reset-password', validateId('id'), c.resetPassword);
router.patch('/:id/deactivate', validateId('id'), c.deactivate);
router.patch('/:id/reactivate', validateId('id'), c.reactivate);

// Exercise program and progress of one patient
router.get('/:id/assignments', validateId('id'), a.listForPatient);
router.post('/:id/assignments', validateId('id'), a.create);
router.get('/:id/completions', validateId('id'), a.completionsForPatient);

module.exports = router;