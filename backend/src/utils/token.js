const jwt = require('jsonwebtoken');

function getSecret() {
    if (!process.env.JWT_SECRET) throw new Error('JWT_SECRET is missing in .env');
    return process.env.JWT_SECRET;
}

function signToken(user) {
    return jwt.sign({ sub: String(user._id), role: user.role }, getSecret(), {
        expiresIn: process.env.JWT_EXPIRES_IN || '30d',
    });
}

function verifyToken(token) {
    return jwt.verify(token, getSecret());
}

module.exports = { signToken, verifyToken };
