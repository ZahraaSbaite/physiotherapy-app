require('dotenv').config();
const { hashPassword, comparePassword } = require('../utils/password');
const { signToken, verifyToken } = require('../utils/token');

(async () => {
    const hash = await hashPassword('Test1234!');
    console.log('hash starts with:', hash.slice(0, 7));
    console.log('correct password accepted:', await comparePassword('Test1234!', hash));
    console.log('wrong password accepted:', await comparePassword('wrong', hash));

    const token = signToken({ _id: 'abc123', role: 'admin' });
    const payload = verifyToken(token);
    console.log('token payload:', payload.sub, payload.role);

    try {
        verifyToken(token + 'x');
        console.log('tampered token accepted: true (BAD)');
    } catch {
        console.log('tampered token accepted: false');
    }
})();