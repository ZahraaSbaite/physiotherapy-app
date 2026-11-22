const mongoose = require('mongoose');
const Assignment = require('../models/Assignment');
const Appointment = require('../models/Appointment');
const Completion = require('../models/Completion');
const Exercise = require('../models/Exercise');
const HttpError = require('../utils/HttpError');
const { scopeFilter, findOwnPatient } = require('../utils/ownership');
const S = require('../utils/schedule');

const REPEAT_TYPES = ['auto', 'daily', 'weekly'];
const blank = (v) => v === '' || v === null || v === undefined;

function whole(value, field, min) {
    if (blank(value)) return undefined;
    const n = Number(value);
    if (!Number.isInteger(n) || n < min) throw new HttpError(400, `${field} must be a whole number of ${min} or more`);
    return n;
}

function dateOnly(value, field) {
    // Accepts "YYYY-MM-DD" or a full ISO date (only the date part is used)
    const s = typeof value === 'string' ? value.slice(0, 10) : '';
    if (!S.isYmd(s)) throw new HttpError(400, `${field} must be a date like 2026-12-31`);
    return s;
}

// ---------- Presenting ----------

// One query for the numbers every assignment needs:
// total sessions done, and sessions done per day.
async function completionStats(user, assignmentIds) {
    const stats = new Map(assignmentIds.map((id) => [String(id), { done: 0, byDate: {} }]));
    if (assignmentIds.length === 0) return stats;

    const rows = await Completion.aggregate([
        { $match: { ...scopeFilter(user), assignmentId: { $in: assignmentIds } } },
        { $group: { _id: { a: '$assignmentId', d: '$localDate' }, n: { $sum: 1 } } },
    ]);
    for (const row of rows) {
        const s = stats.get(String(row._id.a));
        if (!s) continue;
        s.done += row.n;
        s.byDate[row._id.d] = row.n;
    }
    return stats;
}

// The shape the Flutter app reads
function present(a, stat, ymd) {
    const o = a.toJSON();
    const out = {
        _id: o._id,
        patientId: o.patientId,
        appointmentId: o.appointmentId,
        nextAppointmentId: o.nextAppointmentId,
        exercise: { _id: o.exerciseId ?? null, ...(o.exerciseSnapshot || {}) },
        sets: o.sets,
        reps: o.reps,
        durationSeconds: o.durationSeconds,
        restSeconds: o.restSeconds,
        instructions: o.instructions,
        startDate: S.toYmd(a.startDate),
        endDate: S.toYmd(a.endDate),
        totalTimes: o.totalTimes,
        repeat: o.repeat,
        reminderTimes: o.reminderTimes || [],
        timezone: o.timezone,
        isActive: o.isActive,
        progress: { done: stat.done, total: o.totalTimes },
    };
    if (ymd) {
        const today = stat.byDate[ymd] || 0;
        out.date = ymd;
        out.completedToday = today;
        out.slotsPerDay = S.slotsPerDay(a);
        out.completed = today >= S.slotsPerDay(a);
    }
    return out;
}

// ---------- Admin ----------

// GET /api/patients/:id/assignments
exports.listForPatient = async (req, res) => {
    const patient = await findOwnPatient(req.user, req.params.id);
    if (!patient) throw new HttpError(404, 'Patient not found');

    const items = await Assignment.find({ adminId: req.user._id, patientId: patient._id, isActive: true }).sort({
        createdAt: -1,
    });
    const stats = await completionStats(
        req.user,
        items.map((a) => a._id)
    );
    res.json({ assignments: items.map((a) => present(a, stats.get(String(a._id)))) });
};

async function ownAppointment(admin, patient, id, field) {
    if (!mongoose.isValidObjectId(id)) throw new HttpError(400, `${field} is invalid`);
    const appointment = await Appointment.findOne({ _id: id, adminId: admin._id, patientId: patient._id });
    if (!appointment) throw new HttpError(404, `${field}: appointment not found for this patient`);
    return appointment;
}

// POST /api/patients/:id/assignments
exports.create = async (req, res) => {
    const patient = await findOwnPatient(req.user, req.params.id);
    if (!patient) throw new HttpError(404, 'Patient not found');
    if (!patient.isActive) throw new HttpError(400, 'This patient account is deactivated');

    const b = req.body;

    const exercise = mongoose.isValidObjectId(b.exerciseId)
        ? await Exercise.findOne({ _id: b.exerciseId, adminId: req.user._id })
        : null;
    if (!exercise) throw new HttpError(404, 'Exercise not found');
    if (exercise.isArchived) throw new HttpError(400, 'This exercise is archived');

    if (blank(b.appointmentId)) throw new HttpError(400, 'appointmentId is required');
    const appointment = await ownAppointment(req.user, patient, b.appointmentId, 'appointmentId');
    const next = blank(b.nextAppointmentId)
        ? undefined
        : await ownAppointment(req.user, patient, b.nextAppointmentId, 'nextAppointmentId');

    const start = dateOnly(b.startDate, 'startDate');
    const end = dateOnly(b.endDate, 'endDate');
    if (end < start) throw new HttpError(400, 'endDate must not be before startDate');
    if (S.diffDays(end, start) >= S.MAX_RANGE_DAYS) throw new HttpError(400, 'An assignment can last at most one year');

    const totalTimes = whole(b.totalTimes, 'totalTimes', 1);
    if (!totalTimes) throw new HttpError(400, 'totalTimes is required');

    const repeatType = b.repeat?.type ?? 'auto';
    if (!REPEAT_TYPES.includes(repeatType)) throw new HttpError(400, `repeat.type must be one of: ${REPEAT_TYPES.join(', ')}`);
    const daysOfWeek = [...new Set((b.repeat?.daysOfWeek ?? []).map(Number))].sort();
    if (daysOfWeek.some((d) => !Number.isInteger(d) || d < 0 || d > 6)) {
        throw new HttpError(400, 'repeat.daysOfWeek must use 0 (Sunday) to 6 (Saturday)');
    }

    const reminderTimes = [...new Set(b.reminderTimes ?? [])].sort();
    if (reminderTimes.length > 6) throw new HttpError(400, 'At most 6 reminder times');

    const timezone = blank(b.timezone) ? undefined : String(b.timezone);
    if (timezone && !S.isValidTimezone(timezone)) throw new HttpError(400, 'Invalid timezone');

    const assignment = new Assignment({
        adminId: req.user._id,
        patientId: patient._id,
        appointmentId: appointment._id,
        nextAppointmentId: next?._id,
        exerciseId: exercise._id,
        exerciseSnapshot: {
            title: exercise.title,
            description: exercise.description,
            videoUrl: exercise.videoUrl,
            imageUrls: exercise.imageUrls,
            precautions: exercise.precautions,
        },
        sets: whole(b.sets, 'sets', 1) ?? exercise.defaultSets,
        reps: whole(b.reps, 'reps', 1) ?? exercise.defaultReps,
        durationSeconds: whole(b.durationSeconds, 'durationSeconds', 1) ?? exercise.defaultDurationSeconds,
        restSeconds: whole(b.restSeconds, 'restSeconds', 0) ?? exercise.defaultRestSeconds,
        instructions: blank(b.instructions) ? undefined : String(b.instructions).trim(),
        startDate: S.fromYmd(start),
        endDate: S.fromYmd(end),
        totalTimes,
        repeat: { type: repeatType, daysOfWeek: repeatType === 'weekly' ? daysOfWeek : [] },
        reminderTimes,
        ...(timezone ? { timezone } : {}),
    });

    await assignment.validate();

    const possible = S.maxSessions(assignment);
    if (totalTimes > possible) {
        throw new HttpError(
            400,
            `totalTimes (${totalTimes}) is more than fits in this schedule (${possible}). Use a longer date range, more days, or fewer sessions`
        );
    }

    await assignment.save();
    res.status(201).json({ assignment: present(assignment, { done: 0, byDate: {} }) });
};

// DELETE /api/assignments/:id
// With completions it is switched off (history stays), otherwise removed.
exports.remove = async (req, res) => {
    const assignment = await Assignment.findOne({ _id: req.params.id, adminId: req.user._id });
    if (!assignment) throw new HttpError(404, 'Assignment not found');

    const hasHistory = await Completion.exists({ adminId: req.user._id, assignmentId: assignment._id });
    if (hasHistory) {
        assignment.isActive = false;
        await assignment.save();
        return res.json({ message: 'Assignment stopped. Its history is kept', archived: true });
    }

    await Assignment.deleteOne({ _id: assignment._id, adminId: req.user._id });
    res.json({ message: 'Assignment removed', archived: false });
};

// GET /api/patients/:id/completions
exports.completionsForPatient = async (req, res) => {
    const patient = await findOwnPatient(req.user, req.params.id);
    if (!patient) throw new HttpError(404, 'Patient not found');
    await listCompletions({ adminId: req.user._id, patientId: patient._id }, req, res);
};

// ---------- Patient ----------

async function listCompletions(filter, req, res) {
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 200, 1), 500);
    const completions = await Completion.find(filter).sort({ completedAt: -1 }).limit(limit);
    res.json({ completions });
}

// GET /api/me/completions
exports.listMyCompletions = (req, res) => listCompletions(scopeFilter(req.user), req, res);

// GET /api/me/assignments?date=YYYY-MM-DD   (the exercises due on that day)
exports.listMine = async (req, res) => {
    const wanted = req.query.date;
    if (wanted !== undefined && !S.isYmd(wanted)) throw new HttpError(400, 'date must look like 2026-12-31');

    const items = await Assignment.find({ ...scopeFilter(req.user), isActive: true });
    const stats = await completionStats(
        req.user,
        items.map((a) => a._id)
    );

    const out = [];
    for (const a of items) {
        const ymd = wanted || S.todayIn(a.timezone);
        const stat = stats.get(String(a._id));
        const doneThatDay = stat.byDate[ymd] || 0;
        const stillOpen = stat.done < a.totalTimes;
        if (S.isDueOn(a, ymd) && (stillOpen || doneThatDay > 0)) out.push(present(a, stat, ymd));
    }
    out.sort((x, y) => x.exercise.title.localeCompare(y.exercise.title));

    res.json({ assignments: out });
};

// GET /api/me/assignments/:id
exports.getMine = async (req, res) => {
    const a = await Assignment.findOne({ _id: req.params.id, ...scopeFilter(req.user), isActive: true });
    if (!a) throw new HttpError(404, 'Exercise not found');

    const stats = await completionStats(req.user, [a._id]);
    res.json({ assignment: present(a, stats.get(String(a._id)), S.todayIn(a.timezone)) });
};

// POST /api/me/assignments/:id/complete
// body: { painLevel?: 0-10, patientNote?: string, date?: 'YYYY-MM-DD', scheduledTime?: 'HH:MM' }
exports.complete = async (req, res) => {
    const a = await Assignment.findOne({ _id: req.params.id, ...scopeFilter(req.user), isActive: true });
    if (!a) throw new HttpError(404, 'Exercise not found');

    const b = req.body;

    // Which day this counts for: the phone's date, if it is close to the real one
    const today = S.todayIn(a.timezone);
    let localDate = today;
    if (b.date !== undefined) {
        if (!S.isYmd(b.date)) throw new HttpError(400, 'date must look like 2026-12-31');
        if (Math.abs(S.diffDays(b.date, today)) > 1) {
            throw new HttpError(400, "Your phone's date looks wrong. Check it and try again");
        }
        localDate = b.date;
    }
    if (!S.isDueOn(a, localDate)) throw new HttpError(400, 'This exercise is not scheduled for today');

    let painLevel;
    if (!blank(b.painLevel)) {
        painLevel = Number(b.painLevel);
        if (!Number.isInteger(painLevel) || painLevel < 0 || painLevel > 10) {
            throw new HttpError(400, 'painLevel must be a whole number from 0 to 10');
        }
    }
    const patientNote = blank(b.patientNote) ? undefined : String(b.patientNote).trim() || undefined;

    const [done, doneThatDay, doneTimes] = await Promise.all([
        Completion.countDocuments({ assignmentId: a._id }),
        Completion.countDocuments({ assignmentId: a._id, localDate }),
        Completion.distinct('scheduledTime', { assignmentId: a._id, localDate }),
    ]);
    if (done >= a.totalTimes) throw new HttpError(409, `All ${a.totalTimes} sessions are already done`);
    if (doneThatDay >= S.slotsPerDay(a)) throw new HttpError(409, 'Already completed for today');

    // With reminder times, each one is a session of its own
    let scheduledTime;
    if (a.reminderTimes.length > 0) {
        if (!blank(b.scheduledTime)) {
            if (!a.reminderTimes.includes(b.scheduledTime)) throw new HttpError(400, 'scheduledTime is not one of the reminder times');
            if (doneTimes.includes(b.scheduledTime)) throw new HttpError(409, 'That session is already completed');
            scheduledTime = b.scheduledTime;
        } else {
            scheduledTime = a.reminderTimes.find((t) => !doneTimes.includes(t));
        }
    }

    let completion;
    try {
        completion = await Completion.create({
            adminId: a.adminId,
            patientId: a.patientId,
            assignmentId: a._id,
            appointmentId: a.appointmentId,
            exerciseTitle: a.exerciseSnapshot.title,
            localDate,
            scheduledTime,
            sequenceNumber: done + 1,
            patientNote,
            painLevel,
        });
    } catch (err) {
        // Double tap, or a retry after a bad connection
        if (err.code === 11000) throw new HttpError(409, 'This session was already recorded');
        throw err;
    }

    res.status(201).json({ completion, progress: { done: done + 1, total: a.totalTimes } });
};
