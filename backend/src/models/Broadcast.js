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
    imageUrl: String, // 👈 ADDED: Optional image link for the broadcast
    audience: { type: audienceSchema, required: true },
    recipientIds: [{ type: Schema.Types.ObjectId, ref: 'User' }],
    readBy: [{ type: Schema.Types.ObjectId, ref: 'User' }],
    sentAt: { type: Date, required: true, default: Date.now },
  },
  { timestamps: { createdAt: true, updatedAt: true } } // 👈 ADDED: updatedAt for edits
);

broadcastSchema.pre('validate', function () {
  if (this.audience?.type === 'selected' && !(this.audience.patientIds?.length > 0)) {
    this.invalidate('audience.patientIds', 'Choose at least one patient');
  }
});

broadcastSchema.index({ adminId: 1, sentAt: -1 });
broadcastSchema.index({ recipientIds: 1, sentAt: -1 });

broadcastSchema.set('toJSON', {
  transform(doc, ret) {
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Broadcast', broadcastSchema);