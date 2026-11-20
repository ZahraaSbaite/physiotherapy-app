require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/User');
const authRoutes = require('../routes/auth');
const { authenticate, requireRole } = require('../middleware/auth');
const validateId = require('../middleware/validateId');
const { findOwnPatient, scopeFilter } = require('../utils/ownership');
const { errorHandler } = require('../middleware/errorHandler');
const { hashPassword } = require('../utils/password');

const PASSWORD = 'TestPass123!';
const EMAILS = {
    adminA: 'zz-test-admin-a@example.test',
    adminB: 'zz-test-admin-b@example.test',
    patientA: 'zz-test-patient-a@example.test',
    patientB: 'zz-test-patient-b@example.test',
    inactive: 'zz-test-inactive@example.test',
};

let passed = 0;
let failed = 0;
function check(name, condition) {
    if (condition) {
        passed++;
        console.log('PASS  ' + name);
    } else {
        failed++;
        console.log('FAIL  ' + name);
    }
}

const cleanup = () => User.deleteMany({ email: { $in: Object.values(EMAILS) } });

// A small app that uses the real middleware
const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);
app.get('/t/admin-only', authenticate, requireRole('admin'), (req, res) => res.json({ ok: true }));
app.get('/t/patients/:id', authenticate, requireRole('admin'), validateId('id'), async (req, res) => {
    const patient = await findOwnPatient(req.user, req.params.id);
    if (!patient) return res.status(404).json({ message: 'Patient not found' });
    res.json({ patient });
});
app.use(errorHandler);

async function main() {
    await mongoose.connect(process.env.MONGODB_URI);
    await cleanup();

    const passwordHash = await hashPassword(PASSWORD);
    const adminA = await User.create({ role: 'admin', name: 'Test Admin A', email: EMAILS.adminA, passwordHash });
    const adminB = await User.create({ role: 'admin', name: 'Test Admin B', email: EMAILS.adminB, passwordHash });
    const patientA = await User.create({ role: 'patient', name: 'Test Patient A', email: EMAILS.patientA, passwordHash, adminId: adminA._id });
    const patientB = await User.create({ role: 'patient', name: 'Test Patient B', email: EMAILS.patientB, passwordHash, adminId: adminB._id });
    await User.create({ role: 'patient', name: 'Test Inactive', email: EMAILS.inactive, passwordHash, adminId: adminA._id, isActive: false });

    const server = await new Promise((resolve) => {
        const s = app.listen(0, () => resolve(s));
    });
    const base = `http://127.0.0.1:${server.address().port}`;

    async function call(method, path, { token, body } = {}) {
        const headers = {};
        if (token) headers.Authorization = `Bearer ${token}`;
        if (body) headers['Content-Type'] = 'application/json';
        const res = await fetch(base + path, { method, headers, body: body ? JSON.stringify(body) : undefined });
        let data = null;
        try {
            data = await res.json();
        } catch { }
        return { status: res.status, data };
    }
    const login = (email, password = PASSWORD) => call('POST', '/api/auth/login', { body: { email, password } });

    try {
        // --- Login check ---
        const noToken = await call('GET', '/api/auth/me');
        check('1. Request without a token is refused (401)', noToken.status === 401);

        const loginA = await login(EMAILS.adminA);
        const tokenA = loginA.data?.token;
        const tampered = await call('GET', '/api/auth/me', { token: tokenA + 'x' });
        check('2. Tampered token is refused (401)', tampered.status === 401);

        check('3. Admin login works (200)', loginA.status === 200 && !!tokenA);
        check('4. Login response has no passwordHash', loginA.data?.user && !('passwordHash' in loginA.data.user));

        const loginPA = await login(EMAILS.patientA);
        const tokenPA = loginPA.data?.token;
        check('5. Patient login works (200)', loginPA.status === 200 && !!tokenPA);

        const wrongPw = await login(EMAILS.adminA, 'not-the-password');
        check('6. Wrong password is refused (401)', wrongPw.status === 401);

        const inactive = await login(EMAILS.inactive);
        check('7. Deactivated patient cannot log in (403)', inactive.status === 403);

        // --- Role check ---
        const adminRoute = await call('GET', '/t/admin-only', { token: tokenA });
        check('8. Admin can use an admin-only route (200)', adminRoute.status === 200);

        const patientRoute = await call('GET', '/t/admin-only', { token: tokenPA });
        check('9. Patient is blocked from an admin-only route (403)', patientRoute.status === 403);

        // --- Ownership check ---
        const own = await call('GET', `/t/patients/${patientA._id}`, { token: tokenA });
        check('10. Admin A can read their own patient (200)', own.status === 200);

        const other = await call('GET', `/t/patients/${patientB._id}`, { token: tokenA });
        check("11. Admin A cannot read Admin B's patient (404)", other.status === 404);

        const badId = await call('GET', '/t/patients/not-an-id', { token: tokenA });
        check('12. Invalid ID format is refused (400)', badId.status === 400);

        const loginB = await login(EMAILS.adminB);
        const crossB = await call('GET', `/t/patients/${patientA._id}`, { token: loginB.data?.token });
        check("13. Admin B cannot read Admin A's patient (404)", crossB.status === 404);

        // --- A patient cannot change protected fields ---
        const edit = await call('PATCH', '/api/auth/me', {
            token: tokenPA,
            body: { name: 'Renamed', role: 'admin', adminId: String(adminB._id), isActive: false, email: 'hacker@example.test' },
        });
        const u = edit.data?.user || {};
        check('14. Patient can change their name', u.name === 'Renamed');
        check('15. Patient cannot change their role', u.role === 'patient');
        check('16. Patient cannot change their adminId', String(u.adminId) === String(adminA._id));
        check('17. Patient cannot deactivate themselves via profile', u.isActive === true);
        check('18. Patient cannot change their email', u.email === EMAILS.patientA);

        // --- Password change rules ---
        const badCurrent = await call('POST', '/api/auth/change-password', {
            token: tokenPA,
            body: { currentPassword: 'wrong-current', newPassword: 'NewPass12345' },
        });
        check('19. Wrong current password is refused (400)', badCurrent.status === 400);

        const shortNew = await call('POST', '/api/auth/change-password', {
            token: tokenPA,
            body: { currentPassword: PASSWORD, newPassword: 'short' },
        });
        check('20. Too-short new password is refused (400)', shortNew.status === 400);

        // --- Ownership filter shapes ---
        const fa = scopeFilter(adminA);
        check('21. Admin filter is only adminId', Object.keys(fa).length === 1 && String(fa.adminId) === String(adminA._id));
        const fp = scopeFilter(patientA);
        check(
            '22. Patient filter is adminId + own patientId',
            Object.keys(fp).length === 2 && String(fp.adminId) === String(adminA._id) && String(fp.patientId) === String(patientA._id)
        );

        // --- Deactivation locks out an existing token immediately ---
        await User.updateOne({ _id: patientA._id }, { isActive: false });
        const afterDeactivate = await call('GET', '/api/auth/me', { token: tokenPA });
        check('23. Deactivated patient is locked out immediately (401)', afterDeactivate.status === 401);
    } finally {
        server.close();
        await cleanup();
        await mongoose.disconnect();
    }

    console.log(`\n${passed} passed, ${failed} failed`);
    console.log(failed === 0 ? 'ALL GOOD. Test users were deleted.' : 'SOMETHING IS WRONG. Test users were deleted.');
    process.exit(failed === 0 ? 0 : 1);
}

main().catch(async (err) => {
    console.error('\nScript error:', err.message);
    try {
        await cleanup();
        await mongoose.disconnect();
    } catch { }
    process.exit(1);
});