const User = require('../models/User');
const HttpError = require('../utils/HttpError');
const { comparePassword, hashPassword } = require('../utils/password');
const { signToken } = require('../utils/token');

// POST /api/auth/login
exports.login = async (req, res) => {
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');
    if (!email || !password) throw new HttpError(400, 'Email and password are required');

    const user = await User.findOne({ email }).select('+passwordHash');

    // Same message for "no such email" and "wrong password"
    // so nobody can discover which emails exist
    if (!user || !(await comparePassword(password, user.passwordHash))) {
        throw new HttpError(401, 'Wrong email or password');
    }
    if (!user.isActive) {
        throw new HttpError(403, 'This account is deactivated. Please contact your therapist');
    }

    user.lastLoginAt = new Date();
    await user.save();

    res.json({ token: signToken(user), user });
};

// GET /api/auth/me
exports.me = async (req, res) => {
    res.json({ user: req.user });
};

// PATCH /api/auth/me
exports.updateMe = async (req, res) => {
    // Only these fields can be changed by the user.
    // Email, role, adminId, isActive and medicalNotes are not editable here.
    const allowed =
        req.user.role === 'admin'
            ? ['name', 'phone', 'profileImageUrl', 'defaultCurrency']
            : ['name', 'phone', 'profileImageUrl', 'dateOfBirth', 'gender'];

    for (const field of allowed) {
        if (req.body[field] !== undefined) req.user[field] = req.body[field];
    }

    await req.user.save();
    res.json({ user: req.user });
};

// POST /api/auth/change-password
exports.changePassword = async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
        throw new HttpError(400, 'Current and new password are required');
    }
    if (String(newPassword).length < 8) {
        throw new HttpError(400, 'New password must be at least 8 characters');
    }

    const user = await User.findById(req.user._id).select('+passwordHash');
    if (!(await comparePassword(String(currentPassword), user.passwordHash))) {
        throw new HttpError(400, 'Current password is wrong');
    }

    user.passwordHash = await hashPassword(String(newPassword));
    await user.save();

    res.json({ message: 'Password changed' });
};

// PUT /api/auth/fcm-token
exports.saveFcmToken = async (req, res) => {
    const { fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== 'string') {
        throw new HttpError(400, 'fcmToken is required');
    }

    // One phone token belongs to one account: remove it from anyone else
    // (for example when two people use the same phone)
    await User.updateMany({ fcmToken, _id: { $ne: req.user._id } }, { $unset: { fcmToken: 1 } });

    req.user.fcmToken = fcmToken;
    await req.user.save();
    res.json({ message: 'Push token saved' });
};

// POST /api/auth/logout
exports.logout = async (req, res) => {
    req.user.fcmToken = undefined;
    await req.user.save();
    res.json({ message: 'Logged out' });
};