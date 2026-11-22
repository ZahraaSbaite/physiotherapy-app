const Broadcast = require('../models/Broadcast');
const User = require('../models/User');
const HttpError = require('../utils/HttpError');
const { ownPatientIds } = require('../utils/ownership');

const clean = (v) => (v === '' || v === null || v === undefined ? undefined : v);

// What the therapist sees in the sent list
function presentForAdmin(b) {
    return {
        _id: b._id,
        title: b.title,
        text: b.text,
        audience: { type: b.audience.type },
        recipientCount: b.recipientIds.length,
        readCount: b.readBy.length,
        sentAt: b.sentAt,
    };
}

// What a patient sees
function presentForPatient(b, userId) {
    return {
        _id: b._id,
        title: b.title,
        text: b.text,
        sentAt: b.sentAt,
        isRead: b.readBy.some((id) => id.equals(userId)),
    };
}

async function loadOwn(req) {
    const broadcast = await Broadcast.findOne({ _id: req.params.id, adminId: req.user._id });
    if (!broadcast) throw new HttpError(404, 'Announcement not found');
    return broadcast;
}

// ---------- Admin ----------

// GET /api/broadcasts
exports.list = async (req, res) => {
    const items = await Broadcast.find({ adminId: req.user._id }).sort({ sentAt: -1 }).limit(100);
    res.json({ broadcasts: items.map(presentForAdmin) });
};

// GET /api/broadcasts/:id  (with who has read it)
exports.getOne = async (req, res) => {
    const broadcast = await loadOwn(req);
    await broadcast.populate('recipientIds', 'name');

    res.json({
        broadcast: {
            ...presentForAdmin(broadcast),
            recipients: broadcast.recipientIds
                .map((r) => ({ _id: r._id, name: r.name, read: broadcast.readBy.some((id) => id.equals(r._id)) }))
                .sort((a, b) => a.name.localeCompare(b.name)),
        },
    });
};

// POST /api/broadcasts   { title?, text, audience: { type: 'all' | 'selected', patientIds? } }
exports.create = async (req, res) => {
    const b = req.body;

    const text = String(b.text ?? '').trim();
    if (!text) throw new HttpError(400, 'Write a message first');

    const type = b.audience?.type ?? 'all';
    if (!['all', 'selected'].includes(type)) throw new HttpError(400, "audience.type must be 'all' or 'selected'");

    let patientIds = [];
    let recipientIds;
    if (type === 'all') {
        recipientIds = await User.find({ adminId: req.user._id, role: 'patient', isActive: true }).distinct('_id');
    } else {
        patientIds = await ownPatientIds(req.user, b.audience?.patientIds, { activeOnly: true });
        recipientIds = patientIds;
    }
    if (recipientIds.length === 0) throw new HttpError(400, 'There are no patients to send this to');

    const broadcast = await Broadcast.create({
        adminId: req.user._id,
        title: clean(b.title),
        text,
        audience: { type, patientIds },
        recipientIds,
    });

    res.status(201).json({ broadcast: presentForAdmin(broadcast) });
};

// DELETE /api/broadcasts/:id
exports.remove = async (req, res) => {
    const broadcast = await loadOwn(req);
    await Broadcast.deleteOne({ _id: broadcast._id, adminId: req.user._id });
    res.json({ message: 'Announcement deleted' });
};

// ---------- Patient ----------

// GET /api/me/broadcasts
exports.listMine = async (req, res) => {
    const items = await Broadcast.find({ adminId: req.user.adminId, recipientIds: req.user._id })
        .sort({ sentAt: -1 })
        .limit(100);
    res.json({ broadcasts: items.map((b) => presentForPatient(b, req.user._id)) });
};

// POST /api/me/broadcasts/:id/read
exports.markRead = async (req, res) => {
    const result = await Broadcast.updateOne(
        { _id: req.params.id, adminId: req.user.adminId, recipientIds: req.user._id },
        { $addToSet: { readBy: req.user._id } }
    );
    if (result.matchedCount === 0) throw new HttpError(404, 'Announcement not found');
    res.json({ message: 'Marked as read' });
};
