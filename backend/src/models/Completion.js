const mongoose = require('mongoose');
const { Schema } = mongoose;

const completionSchema = new Schema(
    {
        adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        assignmentId: { type: Schema.Types.ObjectId, ref: 'Assignment', required: true },
        appointmentId: { type: Schema.Types.ObjectId, ref: 'Appointment', required: true },

        exerciseTitle: { type: String, required: true, trim: true },

        completedAt: { type: Date, required: true, default: Date.now },
        localDate: {
            type: String,
            required: true,
            match: [/^\d{4}-\d{2}-\d{2}$/, 'Use YYYY-MM-DD'],
        },
        scheduledTime: { type: String, match: [/^([01]\d|2[0-3]):[0-5]\d$/, 'Use HH:MM'] },

        sequenceNumber: { type: Number, required: true, min: 1 },

        patientNote: { type: String, trim: true, maxlength: 1000 },
        painLevel: { type: Number, min: 0, max: 10 },

        noteReadByAdmin: { type: Boolean, default: false },
    },
    { timestamps: { createdAt: true, updatedAt: false } }
);

// No double check-offs (double tap or a retry after a bad connection)
completionSchema.index({ assignmentId: 1, sequenceNumber: 1 }, { unique: true });
completionSchema.index({ patientId: 1, completedAt: -1 }); // patient history
completionSchema.index({ adminId: 1, noteReadByAdmin: 1 }); // unread notes badge
completionSchema.index({ appointmentId: 1 }); // history per appointment

completionSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('Completion', completionSchema);