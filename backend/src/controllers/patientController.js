const User = require('../models/User');
const Appointment = require('../models/Appointment');
const Assignment = require('../models/Assignment');
const Completion = require('../models/Completion');
const Channel = require('../models/Channel');
const Broadcast = require('../models/Broadcast');

const HttpError = require('../utils/HttpError');
const { hashPassword } = require('../utils/password');
const { findOwnPatient } = require('../utils/ownership');

// '' and null mean "clear this optional field"
const clean = (v) => (v === '' || v === null ? undefined : v);

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

async function loadPatient(req) {
    const patient = await findOwnPatient(req.user, req.params.id, { withNotes: true });
    if (!patient) throw new HttpError(404, 'Patient not found');
    return patient;
}

// POST /api/patients
exports.create = async (req, res) => {
    const name = String(req.body.name || '').trim();
    const email = String(req.body.email || '').trim();
    const password = req.body.password;

    if (!name) throw new HttpError(400, 'Name is required');
    if (!email) throw new HttpError(400, 'Email is required');
    if (typeof password !== 'string' || password.length < 8) {
        throw new HttpError(400, 'Password must be at least 8 characters');
    }

    const patient = await User.create({
        role: 'patient',
        adminId: req.user._id,
        name,
        email,
        passwordHash: await hashPassword(password),
        phone: clean(req.body.phone),
        dateOfBirth: clean(req.body.dateOfBirth),
        gender: clean(req.body.gender),
        medicalNotes: clean(req.body.medicalNotes),
    });

    res.status(201).json({ patient });
};

// GET /api/patients?search=&isActive=true|false&page=1&limit=50
exports.list = async (req, res) => {
    const filter = { role: 'patient', adminId: req.user._id };

    if (req.query.isActive === 'true') filter.isActive = true;
    if (req.query.isActive === 'false') filter.isActive = false;

    const search = String(req.query.search || '').trim();
    if (search) {
        const rx = new RegExp(escapeRegex(search), 'i');
        filter.$or = [{ name: rx }, { email: rx }, { phone: rx }];
    }

    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 100);

    const [patients, total] = await Promise.all([
        User.find(filter)
            .collation({ locale: 'en' })
            .sort({ name: 1 })
            .skip((page - 1) * limit)
            .limit(limit),
        User.countDocuments(filter),
    ]);

    res.json({ patients, total, page, limit });
};

// GET /api/patients/:id
exports.getOne = async (req, res) => {
    res.json({ patient: await loadPatient(req) });
};

// PATCH /api/patients/:id
exports.update = async (req, res) => {
    const patient = await loadPatient(req);

    const required = ['name', 'email'];
    const optional = ['phone', 'dateOfBirth', 'gender', 'medicalNotes', 'profileImageUrl'];

    for (const field of required) {
        if (req.body[field] === undefined) continue;
        const value = String(req.body[field]).trim();
        if (!value) throw new HttpError(400, `${field} cannot be empty`);
        patient[field] = value;
    }
    for (const field of optional) {
        if (req.body[field] !== undefined) patient[field] = clean(req.body[field]);
    }

    await patient.save();
    res.json({ patient });
};

// POST /api/patients/:id/reset-password
exports.resetPassword = async (req, res) => {
    const { newPassword } = req.body;
    if (typeof newPassword !== 'string' || newPassword.length < 8) {
        throw new HttpError(400, 'New password must be at least 8 characters');
    }

    const patient = await loadPatient(req);
    patient.passwordHash = await hashPassword(newPassword);
    await patient.save();

    res.json({ message: 'Password reset' });
};

// PATCH /api/patients/:id/deactivate  (level 1 delete)
exports.deactivate = async (req, res) => {
    const patient = await loadPatient(req);
    patient.isActive = false;
    patient.fcmToken = undefined; // stop push notifications
    await patient.save();
    res.json({ patient });
};

// PATCH /api/patients/:id/reactivate
exports.reactivate = async (req, res) => {
    const patient = await loadPatient(req);
    patient.isActive = true;
    await patient.save();
    res.json({ patient });
};

// DELETE /api/patients/:id?confirm=true  (level 2 delete, permanent)
exports.remove = async (req, res) => {
    if (req.query.confirm !== 'true') {
        throw new HttpError(400, 'Permanent delete must be confirmed (add ?confirm=true)');
    }

    const patient = await loadPatient(req);
    const id = patient._id;
    const adminId = req.user._id;
    const deleted = {};

    // Everything linked to the patient goes first, and the user itself goes
    // last, so if something fails halfway the delete can simply be run again.
    deleted.completions = (await Completion.deleteMany({ adminId, patientId: id })).deletedCount;
    deleted.assignments = (await Assignment.deleteMany({ adminId, patientId: id })).deletedCount;
    deleted.appointments = (await Appointment.deleteMany({ adminId, patientId: id })).deletedCount;

    await Channel.updateMany({ adminId, memberIds: id }, { $pull: { memberIds: id } });
    await Broadcast.updateMany(
        {
            adminId,
            $or: [{ recipientIds: id }, { readBy: id }, { 'audience.patientIds': id }],
        },
        { $pull: { recipientIds: id, readBy: id, 'audience.patientIds': id } }
    );

    await User.deleteOne({ _id: id, adminId, role: 'patient' });

    res.json({ message: 'Patient permanently deleted', deleted });
};