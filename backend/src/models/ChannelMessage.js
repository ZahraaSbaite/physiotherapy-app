const mongoose = require('mongoose');
const { Schema } = mongoose;

const channelMessageSchema = new Schema(
    {
        channelId: { type: Schema.Types.ObjectId, ref: 'Channel', required: true },
        adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true },

        senderId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        senderRole: { type: String, enum: ['admin', 'patient'], required: true },

        text: { type: String, required: true, trim: true, maxlength: 4000 },
        attachmentUrl: String,

        clientMessageId: { type: String, required: true },
        readBy: [{ type: Schema.Types.ObjectId, ref: 'User' }],

        editedAt: Date,
        isDeleted: { type: Boolean, default: false },
    },
    { timestamps: { createdAt: true, updatedAt: false } }
);

channelMessageSchema.index({ channelId: 1, createdAt: -1 }); // load a channel
channelMessageSchema.index({ channelId: 1, clientMessageId: 1 }, { unique: true }); // no duplicates

channelMessageSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('ChannelMessage', channelMessageSchema);