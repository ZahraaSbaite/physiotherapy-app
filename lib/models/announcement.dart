class Broadcast {
  final String id;
  final String? title;
  final String text;
  final String? imageUrl;
  final String audienceType;
  final int recipientCount;
  final int readCount;
  final DateTime sentAt;
  final DateTime? updatedAt;
  final List<BroadcastRecipient> recipients;
  final bool isRead;

  const Broadcast({
    required this.id,
    this.title,
    required this.text,
    this.imageUrl,
    required this.audienceType,
    required this.recipientCount,
    required this.readCount,
    required this.sentAt,
    this.updatedAt,
    this.recipients = const [],
    this.isRead = false,
  });

  // 👇 Convenience getters the existing widgets rely on
  bool get sentToAll => audienceType == 'all';

  String get headline {
    final t = (title ?? '').trim();
    if (t.isNotEmpty) return t;
    final first = text.trim().split('\n').first;
    return first.length > 60 ? '${first.substring(0, 60)}…' : first;
  }

  factory Broadcast.fromJson(
    Map<String, dynamic> j, {
    bool forAdmin = false,
  }) {
    return Broadcast(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      title: j['title'] as String?,
      text: (j['text'] ?? '').toString(),
      imageUrl: j['imageUrl'] as String?,
      audienceType: (j['audience']?['type'] ?? 'all').toString(),
      recipientCount: j['recipientCount'] as int? ?? 0,
      readCount: j['readCount'] as int? ?? 0,
      sentAt: DateTime.parse(j['sentAt'].toString()).toLocal(),
      updatedAt:
          j['updatedAt'] != null
              ? DateTime.parse(j['updatedAt'].toString()).toLocal()
              : null,
      recipients:
          forAdmin && j['recipients'] is List
              ? (j['recipients'] as List)
                  .map(
                    (e) => BroadcastRecipient.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList()
              : const [],
      isRead: j['isRead'] as bool? ?? false,
    );
  }
}

class BroadcastRecipient {
  final String id;
  final String name;
  final bool read;
  const BroadcastRecipient({
    required this.id,
    required this.name,
    required this.read,
  });
  factory BroadcastRecipient.fromJson(Map<String, dynamic> j) =>
      BroadcastRecipient(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        read: j['read'] as bool? ?? false,
      );
}

class ChannelMember {
  final String id;
  final String name;
  const ChannelMember({required this.id, required this.name});
  factory ChannelMember.fromJson(Map<String, dynamic> j) =>
      ChannelMember(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
      );
}

class Channel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool membersCanReply;
  final bool isArchived;
  final int memberCount;
  final DateTime? lastMessageAt;
  final ChannelLastMessage? lastMessage;
  final int unreadCount;
  final List<ChannelMember> members;

  const Channel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.membersCanReply,
    required this.isArchived,
    required this.memberCount,
    this.lastMessageAt,
    this.lastMessage,
    required this.unreadCount,
    this.members = const [],
  });

  // 👇 Convenience getter the existing ChannelCard relies on
  String? get lastMessageText => lastMessage?.text;

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    description: j['description'] as String?,
    imageUrl: j['imageUrl'] as String?,
    membersCanReply: j['membersCanReply'] as bool? ?? false,
    isArchived: j['isArchived'] as bool? ?? false,
    memberCount: j['memberCount'] as int? ?? 0,
    lastMessageAt:
        j['lastMessageAt'] != null
            ? DateTime.parse(j['lastMessageAt'].toString()).toLocal()
            : null,
    lastMessage:
        j['lastMessage'] != null
            ? ChannelLastMessage.fromJson(
              j['lastMessage'] as Map<String, dynamic>,
            )
            : null,
    unreadCount: j['unreadCount'] as int? ?? 0,
    members:
        j['members'] is List
            ? (j['members'] as List)
                .map(
                  (e) => ChannelMember.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
            : const [],
  );
}

class ChannelLastMessage {
  final String text;
  final String? senderName;
  final DateTime createdAt;
  const ChannelLastMessage({
    required this.text,
    this.senderName,
    required this.createdAt,
  });
  factory ChannelLastMessage.fromJson(Map<String, dynamic> j) =>
      ChannelLastMessage(
        text: (j['text'] ?? '').toString(),
        senderName: j['senderName'] as String?,
        createdAt:
            DateTime.parse(j['createdAt'].toString()).toLocal(),
      );
}

class ChannelMessage {
  final String id;
  final String channelId;
  final String senderId;
  final String? senderName;
  final String senderRole;
  final String text;
  final String? attachmentUrl;
  final String clientMessageId;
  final List<String> readBy;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final bool isMine;

  const ChannelMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    this.senderName,
    required this.senderRole,
    required this.text,
    this.attachmentUrl,
    required this.clientMessageId,
    required this.readBy,
    required this.createdAt,
    this.editedAt,
    required this.isDeleted,
    required this.isMine,
  });

  factory ChannelMessage.fromJson(
    Map<String, dynamic> j,
    String currentUserId,
  ) {
    final sender = j['senderId'];
    final senderIdStr =
        sender is Map
            ? (sender['_id'] ?? '').toString()
            : (sender ?? '').toString();
    return ChannelMessage(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      channelId: (j['channelId'] ?? '').toString(),
      senderId: senderIdStr,
      senderName: j['senderName'] as String?,
      senderRole: (j['senderRole'] ?? '').toString(),
      text: (j['text'] ?? '').toString(),
      attachmentUrl: j['attachmentUrl'] as String?,
      clientMessageId: (j['clientMessageId'] ?? '').toString(),
      readBy:
          (j['readBy'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      createdAt: DateTime.parse(j['createdAt'].toString()).toLocal(),
      editedAt:
          j['editedAt'] != null
              ? DateTime.parse(j['editedAt'].toString()).toLocal()
              : null,
      isDeleted: j['isDeleted'] as bool? ?? false,
      isMine: senderIdStr == currentUserId,
    );
  }
}

class MessagePage {
  final List<ChannelMessage> messages;
  final bool hasMore;
  final String channelName;
  final bool canWrite;
  const MessagePage({
    required this.messages,
    required this.hasMore,
    required this.channelName,
    required this.canWrite,
  });
}
