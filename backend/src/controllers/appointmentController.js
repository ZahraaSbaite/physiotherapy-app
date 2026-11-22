const mongoose = require('mongoose');
const Appointment = require('../models/Appointment');
const Assignment = require('../models/Assignment');
const HttpError = require('../utils/HttpError');
const { scopeFilter, findOwnPatient } = require('../utils/ownership');
const { buildPayment } = require('../utils/payment');

const STATUSES = ['scheduled', 'completed', 'cancelled', 'no_show'];
const clean = (v) => (v === '' || v === null ? undefined : v);

function parseDate(value, field) {
  const d = new Date(value);
  if (value === undefined || value === null || value === '' || Number.isNaN(d.getTime())) {
    throw new HttpError(400, `${field} must be a valid date`);
  }
  return d;
}

function reminder(value) {
  if (value === '' || value === null) return undefined;
  const n = Number(value);
  if (!Number.isInteger(n) || n < 0) throw new HttpError(400, 'reminderMinutesBefore must be a whole number of 0 or more');
  return n;
}

const populate = (query) => query.populate('patientId', 'name');

async function loadOwn(req) {
  const appointment = await populate(
    Appointment.findOne({ _id: req.params.id, ...scopeFilter(req.user) })
  );
  if (!appointment) throw new HttpError(404, 'Appointment not found');
  return appointment;
}

function rangeFilter(query) {
  const range = {};
  if (query.from) range.$gte = parseDate(query.from, 'from');
  if (query.to) range.$lte = parseDate(query.to, 'to');
  return Object.keys(range).length ? { startTime: range } : {};
}

// 👇 OVERLAP CHECK
async function checkOverlap(adminId, patientId, startTime, endTime, excludeId = null) {
  const query = {
    adminId,
    patientId,
    status: { $in: ['scheduled', 'completed'] },
    startTime: { $lt: endTime },
    endTime: { $gt: startTime },
  };
  if (excludeId) query._id = { $ne: excludeId };
  const existing = await Appointment.findOne(query).populate('patientId', 'name');
  if (existing) {
    const fmt = (d) => d.toLocaleString('en-GB', {
      hour: '2-digit', minute: '2-digit', day: '2-digit', month: 'short'
    });
    throw new HttpError(
      409,
      `Overlaps with existing appointment on ${fmt(existing.startTime)}–${fmt(existing.endTime)}.`
    );
  }
}

// ---------- Admin ----------
exports.list = async (req, res) => {
  const filter = { adminId: req.user._id, ...rangeFilter(req.query) };
  if (req.query.patientId) {
    if (!mongoose.isValidObjectId(req.query.patientId)) throw new HttpError(400, 'Invalid patientId');
    filter.patientId = req.query.patientId;
  }
  if (req.query.status) {
    if (!STATUSES.includes(req.query.status)) throw new HttpError(400, 'Invalid status');
    filter.status = req.query.status;
  }
  const appointments = await populate(Appointment.find(filter).sort({ startTime: 1 }).limit(500));
  res.json({ appointments });
};

exports.getOne = async (req, res) => {
  res.json({ appointment: await loadOwn(req) });
};

// 👇 CREATE with recurrence + overlap check
exports.create = async (req, res) => {
  const b = req.body;
  const patient = await findOwnPatient(req.user, b.patientId);
  if (!patient) throw new HttpError(404, 'Patient not found');
  if (!patient.isActive) throw new HttpError(400, 'This patient account is deactivated');

  const status = b.status ?? 'scheduled';
  if (!STATUSES.includes(status)) throw new HttpError(400, 'Invalid status');

  const startTime = parseDate(b.startTime, 'startTime');
  const endTime = parseDate(b.endTime, 'endTime');
  if (endTime <= startTime) throw new HttpError(400, 'endTime must be after startTime');

  const recurrence = b.recurrence;
  const isWeeklyRecurring =
    recurrence && recurrence.type === 'weekly' && Number(recurrence.count) > 1;

  const toCreate = [];

  if (isWeeklyRecurring) {
    const count = Math.min(Math.max(Number(recurrence.count), 2), 52);
    let curStart = new Date(startTime);
    let curEnd = new Date(endTime);
    for (let i = 0; i < count; i++) {
      toCreate.push({
        adminId: req.user._id,
        patientId: patient._id,
        title: clean(b.title),
        startTime: new Date(curStart),
        endTime: new Date(curEnd),
        status,
        location: clean(b.location),
        notes: clean(b.notes),
        reminderMinutesBefore: reminder(b.reminderMinutesBefore),
        payment:
          b.payment === undefined || b.payment === null
            ? undefined
            : buildPayment(undefined, b.payment, req.user.defaultCurrency),
      });
      curStart.setDate(curStart.getDate() + 7);
      curEnd.setDate(curEnd.getDate() + 7);
    }
  } else {
    toCreate.push({
      adminId: req.user._id,
      patientId: patient._id,
      title: clean(b.title),
      startTime,
      endTime,
      status,
      location: clean(b.location),
      notes: clean(b.notes),
      reminderMinutesBefore: reminder(b.reminderMinutesBefore),
      payment:
        b.payment === undefined || b.payment === null
          ? undefined
          : buildPayment(undefined, b.payment, req.user.defaultCurrency),
    });
  }

  // Overlap check for every slot
  for (const slot of toCreate) {
    await checkOverlap(req.user._id, patient._id, slot.startTime, slot.endTime);
  }

  const created = await Appointment.insertMany(toCreate);
  await Appointment.populate(created, { path: 'patientId', select: 'name' });

  res.status(201).json({
    appointments: created,
    message: isWeeklyRecurring
      ? `Created ${created.length} recurring appointments`
      : 'Appointment created',
  });
};

// 👇 UPDATE with overlap check when time changes
exports.update = async (req, res) => {
  const appointment = await loadOwn(req);
  const b = req.body;

  if (b.patientId !== undefined) {
    const current = String(appointment.patientId._id ?? appointment.patientId);
    if (String(b.patientId) !== current) throw new HttpError(400, 'The patient of an appointment cannot be changed');
  }

  let newStart = appointment.startTime;
  let newEnd = appointment.endTime;

  if (b.startTime !== undefined) newStart = parseDate(b.startTime, 'startTime');
  if (b.endTime !== undefined) newEnd = parseDate(b.endTime, 'endTime');

  if (newEnd <= newStart) throw new HttpError(400, 'endTime must be after startTime');

  // Overlap check only if time changed
  if (b.startTime !== undefined || b.endTime !== undefined) {
    const patientId = appointment.patientId._id ?? appointment.patientId;
    await checkOverlap(req.user._id, patientId, newStart, newEnd, appointment._id);
    appointment.startTime = newStart;
    appointment.endTime = newEnd;
  }

  if (b.status !== undefined) {
    if (!STATUSES.includes(b.status)) throw new HttpError(400, 'Invalid status');
    appointment.status = b.status;
  }
  for (const field of ['title', 'location', 'notes']) {
    if (b[field] !== undefined) appointment[field] = clean(b[field]);
  }
  if (b.reminderMinutesBefore !== undefined) appointment.reminderMinutesBefore = reminder(b.reminderMinutesBefore);
  if (b.payment !== undefined) {
    appointment.payment = buildPayment(appointment.payment, b.payment, req.user.defaultCurrency);
  }

  await appointment.save();
  res.json({ appointment });
};

exports.remove = async (req, res) => {
  const appointment = await loadOwn(req);
  const linked = await Assignment.exists({
    adminId: req.user._id,
    $or: [{ appointmentId: appointment._id }, { nextAppointmentId: appointment._id }],
  });
  if (linked) {
    throw new HttpError(409, 'Exercises are linked to this appointment. Cancel it instead of deleting it');
  }
  await Appointment.deleteOne({ _id: appointment._id, adminId: req.user._id });
  res.json({ message: 'Appointment deleted' });
};

// ---------- Patient ----------
exports.listMine = async (req, res) => {
  const filter = { ...scopeFilter(req.user), ...rangeFilter(req.query) };
  const appointments = await Appointment.find(filter).sort({ startTime: 1 }).limit(500);
  res.json({ appointments });
};

exports.getMine = async (req, res) => {
  const appointment = await Appointment.findOne({ _id: req.params.id, ...scopeFilter(req.user) });
  if (!appointment) throw new HttpError(404, 'Appointment not found');
  res.json({ appointment });
};