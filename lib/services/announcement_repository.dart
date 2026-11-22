import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement.dart';
import 'api_guard.dart';
import 'providers.dart'; // expected to expose apiClientProvider

List<T> _list<T>(dynamic data, String key, T Function(Map<String, dynamic>) f) =>
    (unwrap(data, key) as List).map((e) => f(e as Map<String, dynamic>)).toList();

Map<String, dynamic> _one(dynamic data, String key) =>
    unwrap(data, key) as Map<String, dynamic>;

/// A fresh id for every message, so a retry never creates a duplicate.
String newClientMessageId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}';

/// Which side is asking decides the URL: therapist `/channels/...`, patient `/me/channels/...`.
typedef ChannelKey = ({String id, bool mine});

class AnnouncementRepository {
  AnnouncementRepository(this._dio);
  final Dio _dio;

  String _channelBase(ChannelKey k) => k.mine ? '/me/channels/${k.id}' : '/channels/${k.id}';

  // ---- Broadcasts ----
  Future<List<Broadcast>> broadcasts() => guardApi(() async =>
      _list((await _dio.get('/broadcasts')).data, 'broadcasts', Broadcast.fromJson));

  Future<Broadcast> broadcast(String id) => guardApi(() async =>
      Broadcast.fromJson(_one((await _dio.get('/broadcasts/$id')).data, 'broadcast')));

  Future<void> sendBroadcast({
    String? title,
    required String text,
    required bool toAll,
    List<String> patientIds = const [],
  }) =>
      guardApi(() => _dio.post('/broadcasts', data: {
            if (title != null && title.isNotEmpty) 'title': title,
            'text': text,
            'audience': {
              'type': toAll ? 'all' : 'selected',
              if (!toAll) 'patientIds': patientIds,
            },
          }));

  Future<void> deleteBroadcast(String id) =>
      guardApi(() => _dio.delete('/broadcasts/$id'));

  Future<List<Broadcast>> myBroadcasts() => guardApi(() async =>
      _list((await _dio.get('/me/broadcasts')).data, 'broadcasts', Broadcast.fromJson));

  Future<void> markBroadcastRead(String id) =>
      guardApi(() => _dio.post('/me/broadcasts/$id/read'));

  // ---- Channels ----
  Future<List<Channel>> channels() => guardApi(() async =>
      _list((await _dio.get('/channels')).data, 'channels', Channel.fromJson));

  Future<List<Channel>> myChannels() => guardApi(() async =>
      _list((await _dio.get('/me/channels')).data, 'channels', Channel.fromJson));

  Future<Channel> channel(String id) => guardApi(() async =>
      Channel.fromJson(_one((await _dio.get('/channels/$id')).data, 'channel')));

  Future<void> createChannel({
    required String name,
    String? description,
    required List<String> memberIds,
    required bool membersCanReply,
  }) =>
      guardApi(() => _dio.post('/channels', data: {
            'name': name,
            'description': description ?? '',
            'memberIds': memberIds,
            'membersCanReply': membersCanReply,
          }));

  /// Partial update, e.g. {'isArchived': true}.
  Future<void> updateChannel(String id, Map<String, dynamic> fields) =>
      guardApi(() => _dio.patch('/channels/$id', data: fields));

  // ---- Messages ----
  Future<MessagePage> messages(ChannelKey key, {DateTime? before}) => guardApi(() async {
        final data = (await _dio.get('${_channelBase(key)}/messages', queryParameters: {
          if (before != null) 'before': before.toUtc().toIso8601String(),
        }))
            .data;
        final channel = (data is Map && data['channel'] is Map) ? data['channel'] as Map : const {};
        return MessagePage(
          messages: _list(data, 'messages', ChannelMessage.fromJson),
          hasMore: data is Map && data['hasMore'] == true,
          channelName: (channel['name'] ?? 'Channel').toString(),
          canWrite: !key.mine ||
              (channel['membersCanReply'] == true && channel['isArchived'] != true),
        );
      });

  Future<void> sendMessage(ChannelKey key, String text, String clientMessageId) =>
      guardApi(() => _dio.post('${_channelBase(key)}/messages',
          data: {'text': text, 'clientMessageId': clientMessageId}));

  Future<void> deleteMessage(String channelId, String messageId) =>
      guardApi(() => _dio.delete('/channels/$channelId/messages/$messageId'));

  Future<void> markChannelRead(ChannelKey key) =>
      guardApi(() => _dio.post('${_channelBase(key)}/read'));
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
    (ref) => AnnouncementRepository(ref.watch(apiClientProvider).dio));

final broadcastsProvider = FutureProvider.autoDispose<List<Broadcast>>(
    (ref) => ref.watch(announcementRepositoryProvider).broadcasts());

final broadcastProvider = FutureProvider.autoDispose.family<Broadcast, String>(
    (ref, id) => ref.watch(announcementRepositoryProvider).broadcast(id));

final myBroadcastsProvider = FutureProvider.autoDispose<List<Broadcast>>(
    (ref) => ref.watch(announcementRepositoryProvider).myBroadcasts());

final channelsProvider = FutureProvider.autoDispose<List<Channel>>(
    (ref) => ref.watch(announcementRepositoryProvider).channels());

final myChannelsProvider = FutureProvider.autoDispose<List<Channel>>(
    (ref) => ref.watch(announcementRepositoryProvider).myChannels());

final channelProvider = FutureProvider.autoDispose.family<Channel, String>(
    (ref, id) => ref.watch(announcementRepositoryProvider).channel(id));

final channelMessagesProvider =
    FutureProvider.autoDispose.family<MessagePage, ChannelKey>(
        (ref, key) => ref.watch(announcementRepositoryProvider).messages(key));
