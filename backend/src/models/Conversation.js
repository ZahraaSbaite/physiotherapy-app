const mongoose = require('mongoose');
const { Schema } = mongoose;

const lastMessageSchema = new Schema(
    {
        text: String,
        senderId: { type: Schema.Types.ObjectId, ref: 'User' },
        createdAt: Date,
    },
    { _id: false }
);

const conversationSchema = new Schema(
    {
        adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },

        lastMessage: { type: lastMessageSchema, default: undefined },
        lastMessageAt: { type: Date, default: Date.now },

        unreadForAdmin: { type: Number, default: 0, min: 0 },
        unreadForPatient: { type: Number, default: 0, min: 0 },
    },
    { timestamps: true }
);

conversationSchema.index({ adminId: 1, patientId: 1 }, { unique: true }); // one thread per patient
conversationSchema.index({ adminId: 1, lastMessageAt: -1 }); // admin's chat list

conversationSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('Conversation', conversationSchema);