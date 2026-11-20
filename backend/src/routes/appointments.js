const express = require('express');

const router = express.Router();

// Store appointments in memory until your Mongoose/database model is connected.
// Each item matches the Appointment.fromJson structure expected by the Flutter app.
const appointments = [];

// GET /api/appointments?from=...&to=...
router.get('/', (req, res, next) => {
  try {
    const { from, to } = req.query;
    const fromDate = from ? new Date(from) : null;
    const toDate = to ? new Date(to) : null;

    if (fromDate && Number.isNaN(fromDate.getTime())) {
      return res.status(400).json({ message: 'Invalid "from" date parameter' });
    }
    if (toDate && Number.isNaN(toDate.getTime())) {
      return res.status(400).json({ message: 'Invalid "to" date parameter' });
    }

    const filtered = appointments.filter((item) => {
      const startDate = new Date(item.start);
      if (fromDate && startDate < fromDate) return false;
      if (toDate && startDate > toDate) return false;
      return true;
    });

    return res.json({ appointments: filtered });
  } catch (err) {
    return next(err);
  }
});

// GET /api/appointments/:id
router.get('/:id', (req, res) => {
  const appointment = appointments.find((item) => item.id === req.params.id);
  if (!appointment) {
    return res.status(404).json({ message: 'Appointment not found' });
  }
  return res.json({ appointment });
});

// POST /api/appointments
router.post('/', (req, res, next) => {
  try {
    const {
      patientId,
      patientName,
      start,
      durationMinutes = 60,
      status = 'scheduled',
      notes = '',
      paymentStatus = 'unpaid',
      amount,
    } = req.body;

    if (!start) {
      return res.status(400).json({ message: '"start" is required' });
    }

    const newAppointment = {
      id: Date.now().toString(),
      patientId: patientId ?? '',
      patientName: patientName ?? '',
      start,
      durationMinutes: Number(durationMinutes) || 60,
      status,
      notes,
      paymentStatus,
      ...(amount !== undefined ? { amount: Number(amount) } : {}),
    };

    appointments.push(newAppointment);
    return res.status(201).json({ appointment: newAppointment });
  } catch (err) {
    return next(err);
  }
});

// PUT /api/appointments/:id
router.put('/:id', (req, res) => {
  const index = appointments.findIndex((item) => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ message: 'Appointment not found' });
  }

  const updated = {
    ...appointments[index],
    ...req.body,
    id: appointments[index].id,
  };
  appointments[index] = updated;
  return res.json({ appointment: updated });
});

// PATCH /api/appointments/:id
router.patch('/:id', (req, res) => {
  const index = appointments.findIndex((item) => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ message: 'Appointment not found' });
  }

  const updated = {
    ...appointments[index],
    ...req.body,
    id: appointments[index].id,
  };
  appointments[index] = updated;
  return res.json({ appointment: updated });
});

// DELETE /api/appointments/:id
router.delete('/:id', (req, res) => {
  const index = appointments.findIndex((item) => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ message: 'Appointment not found' });
  }

  appointments.splice(index, 1);
  return res.status(204).send();
});

module.exports = router;