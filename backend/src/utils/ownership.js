const mongoose = require('mongoose');
const User = require('../models/User');
const HttpError = require('./HttpError');

// The admin who owns the data of this user
function adminIdOf(user) {
    return user.role === 'admin' ? user._id : user.adminId;
}

// Query filter for collections that have both adminId and patientId
// (appointments, assignments, completions, messages).
// Admin sees all their patients' data. A patient sees only their own.
function scopeFilter(user) {
    return user.role === 'admin'
        ? { adminId: user._id }
        : { adminId: user.adminId, patientId: user._id };
}

// Returns the patient only if it belongs to this admin, otherwise null.
// medicalNotes are hidden unless withNotes is true.
async function findOwnPatient(admin, patientId, { withNotes = false } = {}) {
    if (!mongoose.isValidObjectId(patientId)) return null;
    const query = User.findOne({ _id: patientId, role: 'patient', adminId: admin._id });
    if (withNotes) query.select('+medicalNotes');
    return query.exec();
}

// Checks that every id is a patient of this admin and returns them as ObjectIds.
// Throws 400 if any id is invalid or belongs to someone else.
async function ownPatientIds(admin, ids, { activeOnly = false } = {}) {
    const list = [...new Set((Array.isArray(ids) ? ids : []).map(String))];
    if (!list.every((id) => mongoose.isValidObjectId(id))) {
        throw new HttpError(400, 'One of the patient ids is invalid');
    }
    const filter = { _id: { $in: list }, role: 'patient', adminId: admin._id };
    if (activeOnly) filter.isActive = true;

    const found = await User.find(filter).select('_id');
    if (found.length !== list.length) {
        throw new HttpError(400, 'Some of the selected patients were not found or are deactivated');
    }
    return found.map((u) => u._id);
}

module.exports = { adminIdOf, scopeFilter, findOwnPatient, ownPatientIds };