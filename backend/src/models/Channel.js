const mongoose = require('mongoose');
const { Schema } = mongoose;

const channelSchema = new Schema(
    {
        adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true },

        name: { type: String, required: true, trim: true },
        description: { type: String, trim: true },
        imageUrl: String,

        memberIds: [{ type: Schema.Types.ObjectId, ref: 'User' }],
        membersCanReply: { type: Boolean, default: false },

        isArchived: { type: Boolean, default: false },
        lastMessageAt: Date,
    },
    { timestamps: true }
);

channelSchema.index({ adminId: 1, isArchived: 1 }); // admin's channels
channelSchema.index({ memberIds: 1 }); // patient's channels

channelSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('Channel', channelSchema);