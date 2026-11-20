const mongoose = require('mongoose');
const { Schema } = mongoose;

const HHMM = /^([01]\d|2[0-3]):[0-5]\d$/;

// Copy of the exercise at assignment time, so history stays correct
// even if the admin later edits or deletes the library entry
const snapshotSchema = new Schema(
    {
        title: { type: String, required: true, trim: true },
        description: String,
        videoUrl: String,
        imageUrls: [String],
        precautions: String,
    },
    { _id: false }
);

const repeatSchema = new Schema(
    {
        type: { type: String, enum: ['auto', 'daily', 'weekly'], default: 'auto' },
        daysOfWeek: [{ type: Number, min: 0, max: 6 }], // 0 = Sunday ... 6 = Saturday
    },
    { _id: false }
);

const assignmentSchema = new Schema(
    {
        adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        appointmentId: { type: Schema.Types.ObjectId, ref: 'Appointment', required: true },
        nextAppointmentId: { type: Schema.Types.ObjectId, ref: 'Appointment' },
        exerciseId: { type: Schema.Types.ObjectId, ref: 'Exercise' },

        exerciseSnapshot: { type: snapshotSchema, required: true },

        sets: { type: Number, min: 1 },
        reps: { type: Number, min: 1 },
        durationSeconds: { type: Number, min: 1 },
        restSeconds: { type: Number, min: 0 },
        instructions: { type: String, trim: true },

        startDate: { type: Date, required: true },
        endDate: { type: Date, required: true },
        totalTimes: { type: Number, required: true, min: 1 },

        repeat: { type: repeatSchema, default: () => ({ type: 'auto' }) },
        reminderTimes: [{ type: String, match: [HHMM, 'Use HH:MM, e.g. 18:00'] }],
        timezone: { type: String, required: true, default: 'Asia/Beirut' },

        isActive: { type: Boolean, default: true },
    },
    { timestamps: true }
);

assignmentSchema.pre('validate', function () {
    if (this.startDate && this.endDate && this.endDate < this.startDate) {
        this.invalidate('endDate', 'endDate must not be before startDate');
    }
    if (this.repeat?.type === 'weekly' && !(this.repeat.daysOfWeek?.length > 0)) {
        this.invalidate('repeat.daysOfWeek', 'Choose at least one day for a weekly repeat');
    }
});

assignmentSchema.index({ patientId: 1, isActive: 1, startDate: 1 }); // patient's list
assignmentSchema.index({ appointmentId: 1 }); // exercises of an appointment
assignmentSchema.index({ adminId: 1, patientId: 1 }); // admin's patient view

assignmentSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('Assignment', assignmentSchema);