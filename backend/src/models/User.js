const mongoose = require('mongoose');
const { Schema } = mongoose;

const userSchema = new Schema(
    {
        role: { type: String, enum: ['admin', 'patient'], required: true },
        name: { type: String, required: true, trim: true },
        email: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
            trim: true,
            match: [/^\S+@\S+\.\S+$/, 'Invalid email address'],
        },
        phone: { type: String, trim: true },
        passwordHash: { type: String, required: true, select: false },

        // Patients only: the admin who owns them
        adminId: { type: Schema.Types.ObjectId, ref: 'User' },

        isActive: { type: Boolean, default: true },

        dateOfBirth: Date,
        gender: { type: String, enum: ['male', 'female', 'other'] },
        medicalNotes: { type: String, trim: true, select: false },
        profileImageUrl: String,

        fcmToken: String,
        lastLoginAt: Date,

        // Admins only: default currency suggested when creating appointments
        defaultCurrency: { type: String, default: 'USD' },
    },
    { timestamps: true }
);

// A patient must have an adminId, an admin must not
userSchema.pre('validate', function () {
    if (this.role === 'patient' && !this.adminId) {
        this.invalidate('adminId', 'A patient must have an adminId');
    }
    if (this.role === 'admin' && this.adminId) {
        this.invalidate('adminId', 'An admin must not have an adminId');
    }
});

// Admin's patient list
userSchema.index({ adminId: 1, role: 1, isActive: 1 });

// Never send the password hash to the app
userSchema.set('toJSON', {
    transform(doc, ret) {
        delete ret.passwordHash;
        delete ret.__v;
        return ret;
    },
});

module.exports = mongoose.model('User', userSchema);