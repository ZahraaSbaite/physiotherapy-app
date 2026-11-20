const mongoose = require('mongoose');
const { Schema } = mongoose;

const exerciseSchema = new Schema(
    {
        adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true },

        title: { type: String, required: true, trim: true },
        description: { type: String, trim: true },
        category: { type: String, trim: true }, // free text, e.g. "Knee"

        videoUrl: { type: String, trim: true },
        imageUrls: [{ type: String, trim: true }],

        defaultSets: { type: Number, min: 1 },
        defaultReps: { type: Number, min: 1 },
        defaultDurationSeconds: { type: Number, min: 1 },
        defaultRestSeconds: { type: Number, min: 0 },

        precautions: { type: String, trim: true },
        isArchived: { type: Boolean, default: false },
    },
    { timestamps: true }
);

exerciseSchema.index({ adminId: 1, category: 1 });
exerciseSchema.index({ adminId: 1, title: 1 });

exerciseSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('Exercise', exerciseSchema);