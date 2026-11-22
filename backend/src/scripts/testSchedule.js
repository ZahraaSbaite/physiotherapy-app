// Offline checks for the schedule and payment rules. No database needed.
// Run: node src/scripts/testSchedule.js
const assert = require('assert');
const S = require('../utils/schedule');
const { buildPayment } = require('../utils/payment');
const Assignment = require('../models/Assignment');

const mk = (o) =>
    new Assignment({
        adminId: '65f000000000000000000001', patientId: '65f000000000000000000002',
        appointmentId: '65f000000000000000000003',
        exerciseSnapshot: { title: 'Bridge' },
        startDate: S.fromYmd('2026-11-23'), endDate: S.fromYmd('2026-12-06'), totalTimes: 10, ...o,
    });

// daily: 14 days
assert.equal(S.dueDays(mk({ repeat: { type: 'daily' } })).length, 14);
// weekly Mon+Wed (1,3): 4 days in two weeks
const weekly = S.dueDays(mk({ repeat: { type: 'weekly', daysOfWeek: [1, 3] } }));
assert.deepEqual(weekly, ['2026-11-23', '2026-11-25', '2026-11-30', '2026-12-02']);
// auto: 10 sessions spread over 14 days, distinct, starts on day 1
const auto = S.dueDays(mk({ repeat: { type: 'auto' } }));
assert.equal(auto.length, 10); assert.equal(new Set(auto).size, 10); assert.equal(auto[0], '2026-11-23');
// two reminder times per day doubles capacity
assert.equal(S.maxSessions(mk({ repeat: { type: 'daily' }, reminderTimes: ['08:00', '18:00'] })), 28);
// weekly without days is invalid, bad reminder time is invalid
// dates and time zones
assert.ok(S.isYmd('2026-02-28') && !S.isYmd('2026-02-30') && !S.isYmd('26-1-1'));
assert.equal(S.weekdayOf('2026-11-22'), 0); // Sunday
assert.equal(S.todayIn('Asia/Beirut', new Date('2026-11-22T22:30:00Z')), '2026-11-23');
assert.ok(S.isValidTimezone('Asia/Beirut') && !S.isValidTimezone('Mars/Base'));

// payment
const now = (o) => buildPayment(undefined, o, 'USD');
assert.equal(now({ amount: 50, status: 'paid' }).paidAmount, 50);
assert.equal(now({ amount: 50 }).status, 'unpaid');
assert.equal(now({ amount: 50, status: 'partial', paidAmount: 20 }).paidAmount, 20);
assert.throws(() => now({ amount: 50, status: 'partial', paidAmount: 50 }), /partial/);
assert.throws(() => now({ status: 'bogus' }), /status/);
assert.throws(() => now({ method: 'bitcoin' }), /method/);
const paid = now({ amount: 50, status: 'paid', method: 'cash' });
assert.equal(buildPayment(paid, { status: 'unpaid' }).paidAmount, 0);
assert.equal(buildPayment(undefined, null), undefined);

// model rules (pre-validate hooks only run with the async validate)
(async () => {
    await assert.rejects(mk({ repeat: { type: 'weekly', daysOfWeek: [] } }).validate(), /weekly|day/i);
    await assert.rejects(mk({ reminderTimes: ['25:00'] }).validate(), /HH:MM/);
    await mk({ repeat: { type: 'daily' } }).validate();
    console.log('All schedule and payment checks passed');
})();
