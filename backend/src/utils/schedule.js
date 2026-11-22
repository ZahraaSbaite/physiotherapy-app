// Pure date and schedule helpers for assignments. No database access here.
//
// Date-only values (startDate, endDate) are stored as UTC midnight and are
// always compared as "YYYY-MM-DD" strings, so time zones never shift a day.

const DAY_MS = 24 * 60 * 60 * 1000;
const YMD = /^\d{4}-\d{2}-\d{2}$/;
const MAX_RANGE_DAYS = 366;

function isYmd(s) {
    if (typeof s !== 'string' || !YMD.test(s)) return false;
    const d = new Date(`${s}T00:00:00Z`);
    return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s;
}

const toYmd = (date) => date.toISOString().slice(0, 10);
const fromYmd = (ymd) => new Date(`${ymd}T00:00:00Z`);
const addDays = (ymd, n) => toYmd(new Date(fromYmd(ymd).getTime() + n * DAY_MS));
const diffDays = (a, b) => Math.round((fromYmd(a) - fromYmd(b)) / DAY_MS);

// 0 = Sunday ... 6 = Saturday
const weekdayOf = (ymd) => fromYmd(ymd).getUTCDay();

function daysBetween(startYmd, endYmd) {
    const out = [];
    for (let d = startYmd; d <= endYmd && out.length <= MAX_RANGE_DAYS; d = addDays(d, 1)) {
        out.push(d);
    }
    return out;
}

function isValidTimezone(tz) {
    try {
        new Intl.DateTimeFormat('en-CA', { timeZone: tz });
        return true;
    } catch {
        return false;
    }
}

// Today's date (YYYY-MM-DD) in the given time zone
function todayIn(tz, now = new Date()) {
    return new Intl.DateTimeFormat('en-CA', {
        timeZone: tz,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
    }).format(now);
}

// How many times per day the exercise is done (one per reminder time, at least one)
const slotsPerDay = (a) => Math.max(1, a.reminderTimes?.length || 0);

// Every day on which the assignment is due.
//   daily  -> each day from start to end
//   weekly -> only the chosen weekdays
//   auto   -> the sessions spread evenly over the date range
function dueDays(a) {
    const days = daysBetween(toYmd(a.startDate), toYmd(a.endDate));
    const type = a.repeat?.type || 'auto';

    if (type === 'daily') return days;

    if (type === 'weekly') {
        const chosen = new Set(a.repeat?.daysOfWeek || []);
        return days.filter((d) => chosen.has(weekdayOf(d)));
    }

    const needed = Math.ceil(a.totalTimes / slotsPerDay(a));
    if (needed >= days.length) return days;
    return Array.from({ length: needed }, (_, i) => days[Math.floor((i * days.length) / needed)]);
}

const maxSessions = (a) => dueDays(a).length * slotsPerDay(a);
const isDueOn = (a, ymd) => dueDays(a).includes(ymd);

module.exports = {
    MAX_RANGE_DAYS,
    isYmd,
    toYmd,
    fromYmd,
    addDays,
    diffDays,
    weekdayOf,
    daysBetween,
    isValidTimezone,
    todayIn,
    slotsPerDay,
    dueDays,
    maxSessions,
    isDueOn,
};
