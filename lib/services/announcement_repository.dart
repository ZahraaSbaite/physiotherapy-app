import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement.dart';
import '../services/auth_controller.dart';
import 'api_guard.dart';
import 'providers.dart';

List<T> _list<T>(
  dynamic data,
  String key,
  T Function(Map<String, dynamic>) f,
) =>
    (unwrap(data, key) as List)
        .map((e) => f(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _one(dynamic data, String key) =>
    unwrap(data, key) as Map<String, dynamic>;

typedef ChannelKey = ({String id, bool mine});

class AnnouncementRepository {
  AnnouncementRepository(this._dio, this._ref);
  final Dio _dio;
  final Ref _ref;

  String get _currentUserId =>
      _ref.read(authControllerProvider).user!.id;

  // ---------- Admin: Broadcasts ----------
  Future<List<Broadcast>> listBroadcasts() => guardApi(
    () async => _list(
      (await _dio.get('/broadcasts')).data,
      'broadcasts',
      (j) => Broadcast.fromJson(j, forAdmin: true),
    ),
  );

  Future<Broadcast> getBroadcast(String id) => guardApi(
    () async => Broadcast.fromJson(
      _one((await _dio.get('/broadcasts/$id')).data, 'broadcast'),
      forAdmin: true,
    ),
  );

  Future<void> createBroadcast({
    required String text,
    String? title,
    String? imageUrl,
    required String audienceType,
    List<String>? patientIds,
  }) => guardApi(
    () => _dio.post(
      '/broadcasts',
      data: {
        'text': text,
        if (title != null && title.isNotEmpty) 'title': title,
        if (imageUrl != null && imageUrl.isNotEmpty)
          'imageUrl': imageUrl,
        'audience': {
          'type': audienceType,
          if (patientIds != null) 'patientIds': patientIds,
        },
      },
    ),
  );

  Future<void> updateBroadcast(
    String id, {
    String? title,
    String? text,
    String? imageUrl,
  }) => guardApi(
    () => _dio.patch(
      '/broadcasts/$id',
      data: {
        if (title != null) 'title': title,
        if (text != null) 'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    ),
  );

  Future<void> deleteBroadcast(String id) =>
      guardApi(() => _dio.delete('/broadcasts/$id'));

  // ---------- Patient: Broadcasts ----------
  Future<List<Broadcast>> listMyBroadcasts() => guardApi(
    () async => _list(
      (await _dio.get('/me/broadcasts')).data,
      'broadcasts',
      (j) => Broadcast.fromJson(j),
    ),
  );

  Future<void> markBroadcastRead(String id) =>
      guardApi(() => _dio.post('/me/broadcasts/$id/read'));

  // ---------- Admin: Channels ----------
  Future<List<Channel>> listChannels({
    bool includeArchived = false,
  }) => guardApi(
    () async => _list(
      (await _dio.get(
        '/channels',
        queryParameters: {
          'includeArchived': includeArchived ? 'true' : 'false',
        },
      )).data,
      'channels',
      Channel.fromJson,
    ),
  );

  Future<Channel> getChannel(String id) => guardApi(
    () async => Channel.fromJson(
      _one((await _dio.get('/channels/$id')).data, 'channel'),
    ),
  );

  Future<void> createChannel({
    required String name,
    String? description,
    String? imageUrl,
    List<String>? memberIds,
    bool membersCanReply = false,
  }) => guardApi(
    () => _dio.post(
      '/channels',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (memberIds != null) 'memberIds': memberIds,
        'membersCanReply': membersCanReply,
      },
    ),
  );

  // 👇 FIX: takes a Map so both the edit form and the archive button work
  Future<void> updateChannel(String id, Map<String, dynamic> patch) =>
      guardApi(() => _dio.patch('/channels/$id', data: patch));

  // ---------- Messages (admin + member) ----------
  Future<MessagePage> listMessages(
    ChannelKey key, {
    DateTime? before,
    int limit = 50,
  }) => guardApi(() async {
    final path =
        key.mine
            ? '/me/channels/${key.id}/messages'
            : '/channels/${key.id}/messages';
    final res = await _dio.get(
      path,
      queryParameters: {
        if (before != null)
          'before': before.toUtc().toIso8601String(),
        'limit': limit,
      },
    );
    final data = res.data;
    final messages =
        (data['messages'] as List)
            .map(
              (e) => ChannelMessage.fromJson(
                e as Map<String, dynamic>,
                _currentUserId,
              ),
            )
            .toList();
    final ch = data['channel'] as Map<String, dynamic>?;
    final membersCanReply =
        (ch?['membersCanReply'] as bool?) ?? false;
    return MessagePage(
      messages: messages,
      hasMore: data['hasMore'] as bool,
      channelName: (ch?['name'] ?? '').toString(),
      // Admins can always write; patients only when membersCanReply
      canWrite: key.mine ? membersCanReply : true,
    );
  });

  Future<void> sendMessage(
    ChannelKey key,
    String text,
    String clientMessageId, {
    String? attachmentUrl,
  }) => guardApi(() {
    final path =
        key.mine
            ? '/me/channels/${key.id}/messages'
            : '/channels/${key.id}/messages';
    return _dio.post(
      path,
      data: {
        'text': text,
        'clientMessageId': clientMessageId,
        if (attachmentUrl != null && attachmentUrl.isNotEmpty)
          'attachmentUrl': attachmentUrl,
      },
    );
  });

  Future<void> updateMessage(
    String channelId,
    String messageId, {
    required String text,
    String? attachmentUrl,
  }) => guardApi(
    () => _dio.patch(
      '/channels/$channelId/messages/$messageId',
      data: {
        'text': text,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      },
    ),
  );

  Future<void> deleteMessage(String channelId, String messageId) =>
      guardApi(
        () => _dio.delete('/channels/$channelId/messages/$messageId'),
      );

  Future<void> markChannelRead(ChannelKey key) => guardApi(() {
    final path =
        key.mine
            ? '/me/channels/${key.id}/read'
            : '/channels/${key.id}/read';
    return _dio.post(path);
  });

  // ---------- Patient: Channels ----------
  Future<List<Channel>> listMyChannels() => guardApi(
    () async => _list(
      (await _dio.get('/me/channels')).data,
      'channels',
      Channel.fromJson,
    ),
  );
}

final announcementRepositoryProvider =
    Provider<AnnouncementRepository>(
      (ref) => AnnouncementRepository(
        ref.watch(apiClientProvider).dio,
        ref,
      ),
    );

// Admin
final broadcastsProvider =
    FutureProvider.autoDispose<List<Broadcast>>(
      (ref) =>
          ref.watch(announcementRepositoryProvider).listBroadcasts(),
    );
final broadcastProvider = FutureProvider.autoDispose
    .family<Broadcast, String>(
      (ref, id) =>
          ref.watch(announcementRepositoryProvider).getBroadcast(id),
    );
final channelsProvider = FutureProvider.autoDispose<List<Channel>>(
  (ref) => ref.watch(announcementRepositoryProvider).listChannels(),
);
// 👇 ADDED: used by ChannelFormScreen when editing
final channelProvider = FutureProvider.autoDispose
    .family<Channel, String>(
      (ref, id) =>
          ref.watch(announcementRepositoryProvider).getChannel(id),
    );

// Patient
final myBroadcastsProvider =
    FutureProvider.autoDispose<List<Broadcast>>(
      (ref) =>
          ref
              .watch(announcementRepositoryProvider)
              .listMyBroadcasts(),
    );
final myChannelsProvider = FutureProvider.autoDispose<List<Channel>>(
  (ref) => ref.watch(announcementRepositoryProvider).listMyChannels(),
);

// Shared
final channelMessagesProvider = FutureProvider.autoDispose
    .family<MessagePage, ChannelKey>(
      (ref, key) =>
          ref.watch(announcementRepositoryProvider).listMessages(key),
    );
