const mongoose = require('mongoose');
const { Schema } = mongoose;

const audienceSchema = new Schema(
    {
        type: { type: String, enum: ['all', 'selected'], required: true },
        patientIds: [{ type: Schema.Types.ObjectId, ref: 'User' }],
    },
    { _id: false }
);

const broadcastSchema = new Schema(
    {
        adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true },

        title: { type: String, trim: true },
        text: { type: String, required: true, trim: true, maxlength: 4000 },

        audience: { type: audienceSchema, required: true },
        // Final list of patients at send time, so history stays accurate
        recipientIds: [{ type: Schema.Types.ObjectId, ref: 'User' }],
        readBy: [{ type: Schema.Types.ObjectId, ref: 'User' }],

        sentAt: { type: Date, required: true, default: Date.now },
    },
    { timestamps: { createdAt: true, updatedAt: false } }
);

broadcastSchema.pre('validate', function () {
    if (this.audience?.type === 'selected' && !(this.audience.patientIds?.length > 0)) {
        this.invalidate('audience.patientIds', 'Choose at least one patient');
    }
});

broadcastSchema.index({ adminId: 1, sentAt: -1 }); // admin's sent list
broadcastSchema.index({ recipientIds: 1, sentAt: -1 }); // patient's received list

broadcastSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('Broadcast', broadcastSchema);