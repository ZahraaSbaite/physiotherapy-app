const mongoose = require('mongoose');
const User = require('../models/User');

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

module.exports = { adminIdOf, scopeFilter, findOwnPatient };