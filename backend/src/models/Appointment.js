const mongoose = require('mongoose');
const { Schema } = mongoose;

// Optional: the whole payment object can be missing (blank)
const paymentSchema = new Schema(
    {
        amount: { type: Number, min: 0 },
        currency: { type: String, default: 'USD' },
        status: { type: String, enum: ['unpaid', 'partial', 'paid'], default: 'unpaid' },
        method: { type: String, enum: ['cash', 'card', 'transfer', 'other'] },
        paidAmount: { type: Number, min: 0, default: 0 },
        paidAt: Date,
        note: { type: String, trim: true },
    },
    { _id: false }
);

const appointmentSchema = new Schema(
    {
        adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },

        title: { type: String, trim: true },
        startTime: { type: Date, required: true },
        endTime: { type: Date, required: true },
        status: {
            type: String,
            enum: ['scheduled', 'completed', 'cancelled', 'no_show'],
            default: 'scheduled',
        },
        location: { type: String, trim: true },
        notes: { type: String, trim: true },
        reminderMinutesBefore: { type: Number, min: 0 },

        payment: { type: paymentSchema, default: undefined },
    },
    { timestamps: true }
);

appointmentSchema.pre('validate', function () {
    if (this.startTime && this.endTime && this.endTime <= this.startTime) {
        this.invalidate('endTime', 'endTime must be after startTime');
    }
});

appointmentSchema.index({ adminId: 1, startTime: 1 }); // calendar
appointmentSchema.index({ patientId: 1, startTime: 1 }); // patient history

appointmentSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('Appointment', appointmentSchema);