const mongoose = require('mongoose');
const Channel = require('../models/Channel');
const ChannelMessage = require('../models/ChannelMessage');
const HttpError = require('../utils/HttpError');
const { ownPatientIds } = require('../utils/ownership');

const blank = (v) => v === '' || v === null;

// ---------- Presenting ----------

// "Unread" means: written by someone else, and I am not in readBy
const unreadFilter = (user, channelId) =>
    user.role === 'admin'
        ? { channelId, senderRole: 'patient', readBy: { $ne: user._id } }
        : { channelId, senderId: { $ne: user._id }, readBy: { $ne: user._id } };

function presentMessage(m, userId) {
    return {
        _id: m._id,
        channelId: m.channelId,
        senderId: m.senderId?._id ?? m.senderId,
        senderName: m.senderId?.name,
        senderRole: m.senderRole,
        text: m.isDeleted ? '' : m.text,
        isDeleted: m.isDeleted,
        isMine: String(m.senderId?._id ?? m.senderId) === String(userId),
        clientMessageId: m.clientMessageId,
        createdAt: m.createdAt,
        editedAt: m.editedAt,
    };
}

async function presentChannel(channel, user) {
    const [last, unreadCount] = await Promise.all([
        ChannelMessage.findOne({ channelId: channel._id, isDeleted: false })
            .sort({ createdAt: -1 })
            .populate('senderId', 'name'),
        ChannelMessage.countDocuments(unreadFilter(user, channel._id)),
    ]);
    const o = channel.toJSON();
    return {
        _id: o._id,
        name: o.name,
        description: o.description,
        imageUrl: o.imageUrl,
        membersCanReply: o.membersCanReply,
        isArchived: o.isArchived,
        memberCount: o.memberIds.length,
        lastMessageAt: o.lastMessageAt,
        lastMessage: last ? { text: last.text, senderName: last.senderId?.name, createdAt: last.createdAt } : null,
        unreadCount,
    };
}

// ---------- Loading with permission checks ----------

async function loadAdminChannel(req) {
    const channel = await Channel.findOne({ _id: req.params.id, adminId: req.user._id });
    if (!channel) throw new HttpError(404, 'Channel not found');
    return channel;
}

async function loadMemberChannel(req) {
    const channel = await Channel.findOne({
        _id: req.params.id,
        adminId: req.user.adminId,
        memberIds: req.user._id,
        isArchived: false,
    });
    if (!channel) throw new HttpError(404, 'Channel not found');
    return channel;
}

const loadChannel = (req) => (req.user.role === 'admin' ? loadAdminChannel(req) : loadMemberChannel(req));

// ---------- Admin: manage channels ----------

function imageUrl(value) {
    if (blank(value)) return undefined;
    const s = String(value).trim();
    if (!/^https?:\/\/\S+$/i.test(s)) throw new HttpError(400, 'imageUrl must be a full link starting with http:// or https://');
    return s;
}

// GET /api/channels?includeArchived=true
exports.list = async (req, res) => {
    const filter = { adminId: req.user._id };
    if (req.query.includeArchived !== 'true') filter.isArchived = false;

    const channels = await Channel.find(filter).sort({ lastMessageAt: -1, createdAt: -1 });
    res.json({ channels: await Promise.all(channels.map((c) => presentChannel(c, req.user))) });
};

// GET /api/channels/:id  (with the member list)
exports.getOne = async (req, res) => {
    const channel = await loadAdminChannel(req);
    await channel.populate('memberIds', 'name');
    const base = await presentChannel(channel, req.user);
    res.json({
        channel: { ...base, members: channel.memberIds.map((m) => ({ _id: m._id, name: m.name })) },
    });
};

// POST /api/channels
exports.create = async (req, res) => {
    const b = req.body;
    const name = String(b.name ?? '').trim();
    if (!name) throw new HttpError(400, 'Name is required');

    const channel = await Channel.create({
        adminId: req.user._id,
        name,
        description: blank(b.description) ? undefined : String(b.description).trim(),
        imageUrl: imageUrl(b.imageUrl),
        memberIds: await ownPatientIds(req.user, b.memberIds ?? [], { activeOnly: true }),
        membersCanReply: b.membersCanReply === true,
    });
    res.status(201).json({ channel: await presentChannel(channel, req.user) });
};

// PATCH /api/channels/:id
exports.update = async (req, res) => {
    const channel = await loadAdminChannel(req);
    const b = req.body;

    if (b.name !== undefined) {
        const name = String(b.name).trim();
        if (!name) throw new HttpError(400, 'Name cannot be empty');
        channel.name = name;
    }
    if (b.description !== undefined) channel.description = blank(b.description) ? undefined : String(b.description).trim();
    if (b.imageUrl !== undefined) channel.imageUrl = imageUrl(b.imageUrl);
    if (b.membersCanReply !== undefined) channel.membersCanReply = b.membersCanReply === true;
    if (b.isArchived !== undefined) channel.isArchived = b.isArchived === true;
    if (b.memberIds !== undefined) {
        if (!Array.isArray(b.memberIds)) throw new HttpError(400, 'memberIds must be a list');
        // Patients who are already members may stay even if deactivated; new ones must be active
        const wanted = [...new Set(b.memberIds.map(String))];
        const existing = new Set(channel.memberIds.map(String));
        const added = wanted.filter((id) => !existing.has(id));
        await ownPatientIds(req.user, added, { activeOnly: true });
        const kept = await ownPatientIds(req.user, wanted.filter((id) => existing.has(id)));
        channel.memberIds = [...kept, ...added.map((id) => new mongoose.Types.ObjectId(id))];
    }

    await channel.save();
    res.json({ channel: await presentChannel(channel, req.user) });
};

// ---------- Messages (admin and members) ----------

// GET /api/channels/:id/messages?before=<ISO date>&limit=50   (and /api/me/channels/:id/messages)
exports.listMessages = async (req, res) => {
    const channel = await loadChannel(req);
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 100);

    const filter = { channelId: channel._id };
    if (req.query.before) {
        const before = new Date(req.query.before);
        if (Number.isNaN(before.getTime())) throw new HttpError(400, 'before must be a valid date');
        filter.createdAt = { $lt: before };
    }

    // Newest first from the database, then flipped so the app can show oldest first
    const rows = await ChannelMessage.find(filter)
        .sort({ createdAt: -1 })
        .limit(limit + 1)
        .populate('senderId', 'name');
    const hasMore = rows.length > limit;
    const messages = rows.slice(0, limit).reverse().map((m) => presentMessage(m, req.user._id));

    res.json({
        messages,
        hasMore,
        channel: { _id: channel._id, name: channel.name, membersCanReply: channel.membersCanReply, isArchived: channel.isArchived },
    });
};

// POST /api/channels/:id/messages   (and /api/me/channels/:id/messages)
// body: { text, clientMessageId }   The app creates clientMessageId so a retry never duplicates.
exports.sendMessage = async (req, res) => {
    const channel = await loadChannel(req);

    if (req.user.role === 'admin' && channel.isArchived) throw new HttpError(400, 'This channel is archived');
    if (req.user.role === 'patient' && !channel.membersCanReply) {
        throw new HttpError(403, 'Only your therapist can write in this channel');
    }

    const text = String(req.body.text ?? '').trim();
    if (!text) throw new HttpError(400, 'Write a message first');
    const clientMessageId = String(req.body.clientMessageId ?? '').trim();
    if (!clientMessageId || clientMessageId.length > 100) throw new HttpError(400, 'clientMessageId is required');

    let message;
    try {
        message = await ChannelMessage.create({
            channelId: channel._id,
            adminId: channel.adminId,
            senderId: req.user._id,
            senderRole: req.user.role,
            text,
            clientMessageId,
            readBy: [req.user._id],
        });
    } catch (err) {
        if (err.code === 11000) {
            // Same message sent again after a bad connection: return the first one
            const existing = await ChannelMessage.findOne({ channelId: channel._id, clientMessageId }).populate('senderId', 'name');
            return res.json({ message: presentMessage(existing, req.user._id) });
        }
        throw err;
    }

    channel.lastMessageAt = message.createdAt;
    await channel.save();

    await message.populate('senderId', 'name');
    res.status(201).json({ message: presentMessage(message, req.user._id) });
};

// DELETE /api/channels/:id/messages/:messageId  (admin; the text is hidden, the row stays)
exports.removeMessage = async (req, res) => {
    const channel = await loadAdminChannel(req);
    const result = await ChannelMessage.updateOne(
        { _id: req.params.messageId, channelId: channel._id },
        { $set: { isDeleted: true } }
    );
    if (result.matchedCount === 0) throw new HttpError(404, 'Message not found');
    res.json({ message: 'Message deleted' });
};

// POST /api/channels/:id/read   (and /api/me/channels/:id/read)
exports.markRead = async (req, res) => {
    const channel = await loadChannel(req);
    await ChannelMessage.updateMany(
        { channelId: channel._id, readBy: { $ne: req.user._id } },
        { $addToSet: { readBy: req.user._id } }
    );
    res.json({ message: 'Marked as read' });
};

// ---------- Patient ----------

// GET /api/me/channels
exports.listMine = async (req, res) => {
    const channels = await Channel.find({
        adminId: req.user.adminId,
        memberIds: req.user._id,
        isArchived: false,
    }).sort({ lastMessageAt: -1, createdAt: -1 });
    res.json({ channels: await Promise.all(channels.map((c) => presentChannel(c, req.user))) });
};
