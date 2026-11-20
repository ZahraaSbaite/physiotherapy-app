const User = require('../models/User');
const { verifyToken } = require('../utils/token');
const HttpError = require('../utils/HttpError');

// 1. Login check: who is calling?
async function authenticate(req, res, next) {
    const [scheme, token] = (req.headers.authorization || '').split(' ');
    if (scheme !== 'Bearer' || !token) throw new HttpError(401, 'Not logged in');

    let payload;
    try {
        payload = verifyToken(token);
    } catch {
        throw new HttpError(401, 'Invalid or expired token');
    }

    // Loaded from the database on every request, so a deactivated
    // account is locked out immediately
    const user = await User.findById(payload.sub);
    if (!user || !user.isActive || user.role !== payload.role) {
        throw new HttpError(401, 'Account not found or deactivated');
    }

    req.user = user;
    next();
}

// 2. Role check: is this role allowed here?
function requireRole(...roles) {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            throw new HttpError(403, 'You do not have permission to do this');
        }
        next();
    };
}

module.exports = { authenticate, requireRole };