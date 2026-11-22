const mongoose = require('mongoose');
const Appointment = require('../models/Appointment');
const Assignment = require('../models/Assignment');
const HttpError = require('../utils/HttpError');
const { scopeFilter, findOwnPatient } = require('../utils/ownership');
const { buildPayment } = require('../utils/payment');

const STATUSES = ['scheduled', 'completed', 'cancelled', 'no_show'];

// '' and null mean "clear this optional field"
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

// ---------- Admin ----------

// GET /api/appointments?from=&to=&patientId=&status=
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

// GET /api/appointments/:id
exports.getOne = async (req, res) => {
    res.json({ appointment: await loadOwn(req) });
};

// POST /api/appointments
exports.create = async (req, res) => {
    const b = req.body;

    const patient = await findOwnPatient(req.user, b.patientId);
    if (!patient) throw new HttpError(404, 'Patient not found');
    if (!patient.isActive) throw new HttpError(400, 'This patient account is deactivated');

    const status = b.status ?? 'scheduled';
    if (!STATUSES.includes(status)) throw new HttpError(400, 'Invalid status');

    const appointment = await Appointment.create({
        adminId: req.user._id,
        patientId: patient._id,
        title: clean(b.title),
        startTime: parseDate(b.startTime, 'startTime'),
        endTime: parseDate(b.endTime, 'endTime'),
        status,
        location: clean(b.location),
        notes: clean(b.notes),
        reminderMinutesBefore: reminder(b.reminderMinutesBefore),
        payment:
            b.payment === undefined || b.payment === null
                ? undefined
                : buildPayment(undefined, b.payment, req.user.defaultCurrency),
    });

    await appointment.populate('patientId', 'name');
    res.status(201).json({ appointment });
};

// PATCH /api/appointments/:id  (send only the fields that change)
exports.update = async (req, res) => {
    const appointment = await loadOwn(req);
    const b = req.body;

    if (b.patientId !== undefined) {
        const current = String(appointment.patientId._id ?? appointment.patientId);
        if (String(b.patientId) !== current) throw new HttpError(400, 'The patient of an appointment cannot be changed');
    }

    if (b.startTime !== undefined) appointment.startTime = parseDate(b.startTime, 'startTime');
    if (b.endTime !== undefined) appointment.endTime = parseDate(b.endTime, 'endTime');
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

// DELETE /api/appointments/:id
exports.remove = async (req, res) => {
    const appointment = await loadOwn(req);

    // Exercises are linked to appointments, so deleting one would orphan them
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

// GET /api/me/appointments?from=&to=
exports.listMine = async (req, res) => {
    const filter = { ...scopeFilter(req.user), ...rangeFilter(req.query) };
    const appointments = await Appointment.find(filter).sort({ startTime: 1 }).limit(500);
    res.json({ appointments });
};

// GET /api/me/appointments/:id
exports.getMine = async (req, res) => {
    const appointment = await Appointment.findOne({ _id: req.params.id, ...scopeFilter(req.user) });
    if (!appointment) throw new HttpError(404, 'Appointment not found');
    res.json({ appointment });
};
