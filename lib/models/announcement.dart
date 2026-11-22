DateTime _date(dynamic v) =>
    DateTime.tryParse((v ?? '').toString())?.toLocal() ?? DateTime.now();

/// One recipient of a broadcast and whether they opened it (therapist view).
class BroadcastRecipient {
  const BroadcastRecipient({required this.id, required this.name, required this.read});

  final String id;
  final String name;
  final bool read;

  factory BroadcastRecipient.fromJson(Map<String, dynamic> j) => BroadcastRecipient(
        id: (j['_id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        read: j['read'] as bool? ?? false,
      );
}

/// A one-way announcement from the therapist to all or selected patients.
class Broadcast {
  const Broadcast({
    required this.id,
    required this.text,
    required this.sentAt,
    this.title,
    this.isRead = true,
    this.sentToAll = true,
    this.recipientCount = 0,
    this.readCount = 0,
    this.recipients = const [],
  });

  final String id;
  final String? title;
  final String text;
  final DateTime sentAt;

  /// Patient view: whether this patient opened it.
  final bool isRead;

  /// Therapist view only.
  final bool sentToAll;
  final int recipientCount;
  final int readCount;
  final List<BroadcastRecipient> recipients;

  String get headline => (title ?? '').trim().isNotEmpty ? title!.trim() : text;

  factory Broadcast.fromJson(Map<String, dynamic> j) {
    final audience = j['audience'] is Map ? j['audience'] as Map : const {};
    return Broadcast(
      id: (j['_id'] ?? '').toString(),
      title: j['title'] as String?,
      text: (j['text'] ?? '').toString(),
      sentAt: _date(j['sentAt']),
      isRead: j['isRead'] as bool? ?? true,
      sentToAll: audience['type'] != 'selected',
      recipientCount: (j['recipientCount'] as num?)?.toInt() ?? 0,
      readCount: (j['readCount'] as num?)?.toInt() ?? 0,
      recipients: (j['recipients'] as List?)
              ?.map((e) => BroadcastRecipient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class ChannelMember {
  const ChannelMember({required this.id, required this.name});

  final String id;
  final String name;

  factory ChannelMember.fromJson(Map<String, dynamic> j) =>
      ChannelMember(id: (j['_id'] ?? '').toString(), name: (j['name'] ?? '').toString());
}

/// A group channel: the therapist posts, and members may reply if allowed.
class Channel {
  const Channel({
    required this.id,
    required this.name,
    this.description,
    this.membersCanReply = false,
    this.isArchived = false,
    this.memberCount = 0,
    this.unreadCount = 0,
    this.lastMessageText,
    this.lastMessageAt,
    this.members = const [],
  });

  final String id;
  final String name;
  final String? description;
  final bool membersCanReply;
  final bool isArchived;
  final int memberCount;
  final int unreadCount;
  final String? lastMessageText;
  final DateTime? lastMessageAt;

  /// Only returned when a single channel is loaded (therapist).
  final List<ChannelMember> members;

  factory Channel.fromJson(Map<String, dynamic> j) {
    final last = j['lastMessage'];
    return Channel(
      id: (j['_id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: j['description'] as String?,
      membersCanReply: j['membersCanReply'] as bool? ?? false,
      isArchived: j['isArchived'] as bool? ?? false,
      memberCount: (j['memberCount'] as num?)?.toInt() ?? 0,
      unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessageText: last is Map ? last['text'] as String? : null,
      lastMessageAt: last is Map ? _date(last['createdAt']) : null,
      members: (j['members'] as List?)
              ?.map((e) => ChannelMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class ChannelMessage {
  const ChannelMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.clientMessageId,
    this.senderName,
    this.senderRole = 'patient',
    this.isMine = false,
    this.isDeleted = false,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String clientMessageId;
  final String? senderName;
  final String senderRole;
  final bool isMine;
  final bool isDeleted;

  bool get fromTherapist => senderRole == 'admin';

  factory ChannelMessage.fromJson(Map<String, dynamic> j) => ChannelMessage(
        id: (j['_id'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
        createdAt: _date(j['createdAt']),
        clientMessageId: (j['clientMessageId'] ?? '').toString(),
        senderName: j['senderName'] as String?,
        senderRole: (j['senderRole'] ?? 'patient').toString(),
        isMine: j['isMine'] as bool? ?? false,
        isDeleted: j['isDeleted'] as bool? ?? false,
      );
}

/// A page of messages (oldest first) and whether older ones exist.
class MessagePage {
  const MessagePage({
    required this.messages,
    required this.hasMore,
    required this.channelName,
    required this.canWrite,
  });

  final List<ChannelMessage> messages;
  final bool hasMore;
  final String channelName;

  /// Whether the current user may post (always true for the therapist).
  final bool canWrite;
}
