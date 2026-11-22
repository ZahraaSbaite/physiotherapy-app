const Exercise = require('../models/Exercise');
const Assignment = require('../models/Assignment');
const HttpError = require('../utils/HttpError');

// '' and null mean "clear this optional field"
const blank = (v) => v === '' || v === null;
const text = (v) => (blank(v) ? undefined : String(v).trim());

function url(value, field) {
    if (blank(value)) return undefined;
    const s = String(value).trim();
    if (!/^https?:\/\/\S+$/i.test(s)) throw new HttpError(400, `${field} must be a full link starting with http:// or https://`);
    return s;
}

function urlList(value, field) {
    if (blank(value)) return [];
    if (!Array.isArray(value)) throw new HttpError(400, `${field} must be a list of links`);
    const list = value.map((v) => url(v, field)).filter(Boolean);
    if (list.length > 10) throw new HttpError(400, `${field} can have at most 10 links`);
    return [...new Set(list)];
}

function whole(value, field, min) {
    if (blank(value)) return undefined;
    const n = Number(value);
    if (!Number.isInteger(n) || n < min) throw new HttpError(400, `${field} must be a whole number of ${min} or more`);
    return n;
}

// Copies only the fields the app is allowed to set
function applyFields(exercise, b, { creating }) {
    if (b.title !== undefined || creating) {
        const title = String(b.title ?? '').trim();
        if (!title) throw new HttpError(400, 'Title is required');
        exercise.title = title;
    }
    if (b.description !== undefined) exercise.description = text(b.description);
    if (b.category !== undefined) exercise.category = text(b.category);
    if (b.precautions !== undefined) exercise.precautions = text(b.precautions);
    if (b.videoUrl !== undefined) exercise.videoUrl = url(b.videoUrl, 'videoUrl');
    if (b.imageUrls !== undefined) exercise.imageUrls = urlList(b.imageUrls, 'imageUrls');
    if (b.defaultSets !== undefined) exercise.defaultSets = whole(b.defaultSets, 'defaultSets', 1);
    if (b.defaultReps !== undefined) exercise.defaultReps = whole(b.defaultReps, 'defaultReps', 1);
    if (b.defaultDurationSeconds !== undefined) {
        exercise.defaultDurationSeconds = whole(b.defaultDurationSeconds, 'defaultDurationSeconds', 1);
    }
    if (b.defaultRestSeconds !== undefined) {
        exercise.defaultRestSeconds = whole(b.defaultRestSeconds, 'defaultRestSeconds', 0);
    }
}

async function loadOwn(req) {
    const exercise = await Exercise.findOne({ _id: req.params.id, adminId: req.user._id });
    if (!exercise) throw new HttpError(404, 'Exercise not found');
    return exercise;
}

// GET /api/exercises?includeArchived=true
exports.list = async (req, res) => {
    const filter = { adminId: req.user._id };
    if (req.query.includeArchived !== 'true') filter.isArchived = false;

    const exercises = await Exercise.find(filter).collation({ locale: 'en' }).sort({ title: 1 });
    res.json({ exercises });
};

// GET /api/exercises/:id
exports.getOne = async (req, res) => {
    res.json({ exercise: await loadOwn(req) });
};

// POST /api/exercises
exports.create = async (req, res) => {
    const exercise = new Exercise({ adminId: req.user._id });
    applyFields(exercise, req.body, { creating: true });
    await exercise.save();
    res.status(201).json({ exercise });
};

// PATCH /api/exercises/:id
exports.update = async (req, res) => {
    const exercise = await loadOwn(req);
    applyFields(exercise, req.body, { creating: false });
    if (req.body.isArchived !== undefined) exercise.isArchived = req.body.isArchived === true;
    await exercise.save();
    res.json({ exercise });
};

// DELETE /api/exercises/:id
// Assignments keep their own copy of the exercise, so history stays correct.
// If the exercise was ever assigned it is archived (hidden), otherwise removed.
exports.remove = async (req, res) => {
    const exercise = await loadOwn(req);

    const used = await Assignment.exists({ adminId: req.user._id, exerciseId: exercise._id });
    if (used) {
        exercise.isArchived = true;
        await exercise.save();
        return res.json({ message: 'Exercise archived', archived: true });
    }

    await Exercise.deleteOne({ _id: exercise._id, adminId: req.user._id });
    res.json({ message: 'Exercise deleted', archived: false });
};
