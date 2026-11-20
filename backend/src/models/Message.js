const mongoose = require('mongoose');
const { Schema } = mongoose;

const messageSchema = new Schema(
    {
        conversationId: { type: Schema.Types.ObjectId, ref: 'Conversation', required: true },
        adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },

        senderId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        senderRole: { type: String, enum: ['admin', 'patient'], required: true },

        type: { type: String, enum: ['text', 'image', 'file'], default: 'text' },
        text: { type: String, trim: true, maxlength: 4000 },
        attachmentUrl: String,

        readAt: Date,
        deliveredAt: Date,

        editedAt: Date,
        originalText: { type: String, select: false }, // server only

        isDeleted: { type: Boolean, default: false },

        // Created by the app, so a retry never creates a duplicate
        clientMessageId: { type: String, required: true },
    },
    { timestamps: { createdAt: true, updatedAt: false } }
);

messageSchema.pre('validate', function () {
    if (!this.isDeleted && this.type === 'text' && !this.text) {
        this.invalidate('text', 'A text message needs text');
    }
});

messageSchema.index({ conversationId: 1, createdAt: -1 }); // load a thread
messageSchema.index({ conversationId: 1, clientMessageId: 1 }, { unique: true }); // no duplicates

messageSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.originalText;
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('Message', messageSchema);