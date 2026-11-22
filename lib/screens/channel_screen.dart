import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/theme/app_colors.dart';
import '../models/announcement.dart';
import '../services/announcement_repository.dart';
import '../utils/formatters.dart';
import '../widgets/announcement_widgets.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';
import '../main.dart'; // for flutterLocalNotificationsPlugin

final _rng = Random();

class ChannelScreen extends ConsumerStatefulWidget {
  const ChannelScreen({
    super.key,
    required this.channelId,
    required this.mine,
  });
  final String channelId;
  final bool mine;

  @override
  ConsumerState<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends ConsumerState<ChannelScreen> {
  final _text = TextEditingController();
  final _attachmentUrl = TextEditingController();
  final List<ChannelMessage> _older = [];
  Timer? _poll;
  bool _loadingOlder = false;
  bool? _olderHasMore;
  bool _sending = false;
  String? _pendingId;
  String? _pendingText;
  String? _lastReadId;

  ChannelKey get _key => (id: widget.channelId, mine: widget.mine);

  // Unique id so a retried send never creates a duplicate on the server.
  String _newClientMessageId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_rng.nextInt(1 << 32)}';

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && !_sending)
        ref.invalidate(channelMessagesProvider(_key));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    _attachmentUrl.dispose();
    super.dispose();
  }

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  void _checkForNewMessages(MessagePage page) {
    if (page.messages.isEmpty) return;
    final latest = page.messages.last;
    if (!latest.isMine &&
        !latest.isDeleted &&
        DateTime.now().difference(latest.createdAt).inSeconds < 30) {
      flutterLocalNotificationsPlugin.show(
        latest.id.hashCode,
        'New message in ${page.channelName}',
        latest.text,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_messages',
            'Channel Messages',
            channelDescription: 'New messages in your channels',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  List<ChannelMessage> _combined(List<ChannelMessage> page) {
    final byId = <String, ChannelMessage>{
      for (final m in [..._older, ...page]) m.id: m,
    };
    return byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _markRead(MessagePage page) async {
    if (page.messages.isEmpty || page.messages.last.id == _lastReadId)
      return;
    _lastReadId = page.messages.last.id;
    _checkForNewMessages(page);
    try {
      await ref
          .read(announcementRepositoryProvider)
          .markChannelRead(_key);
      if (!mounted) return;
      ref.invalidate(
        widget.mine ? myChannelsProvider : channelsProvider,
      );
    } catch (_) {}
  }

  Future<void> _loadOlder(List<ChannelMessage> current) async {
    if (current.isEmpty || _loadingOlder) return;
    setState(() => _loadingOlder = true);
    try {
      // 👇 FIX: repository method is named listMessages, not messages
      final page = await ref
          .read(announcementRepositoryProvider)
          .listMessages(_key, before: current.first.createdAt);
      if (!mounted) return;
      setState(() {
        _older.insertAll(0, page.messages);
        _olderHasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) _toast(errorText(e));
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;

    if (_pendingText != text) {
      // 👇 FIX: use the local helper, not an undefined top-level function
      _pendingId = _newClientMessageId();
      _pendingText = text;
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(announcementRepositoryProvider)
          .sendMessage(
            _key,
            text,
            _pendingId!,
            attachmentUrl:
                _attachmentUrl.text.trim().isEmpty
                    ? null
                    : _attachmentUrl.text.trim(),
          );
      _text.clear();
      _attachmentUrl.clear();
      _pendingId = null;
      _pendingText = null;
      ref.invalidate(channelMessagesProvider(_key));
    } catch (e) {
      if (mounted) _toast(errorText(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _edit(ChannelMessage m) async {
    final controller = TextEditingController(text: m.text);
    final urlController = TextEditingController(
      text: m.attachmentUrl ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Edit message'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                  try {
                    await ref
                        .read(announcementRepositoryProvider)
                        .updateMessage(
                          widget.channelId,
                          m.id,
                          text: controller.text.trim(),
                          attachmentUrl:
                              urlController.text.trim().isEmpty
                                  ? null
                                  : urlController.text.trim(),
                        );
                    _older.removeWhere((o) => o.id == m.id);
                    ref.invalidate(channelMessagesProvider(_key));
                  } catch (e) {
                    if (mounted) _toast(errorText(e));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
    controller.dispose();
    urlController.dispose();
  }

  Future<void> _delete(ChannelMessage m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete message?'),
            content: const Text(
              'Members will see that a message was deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(announcementRepositoryProvider)
          .deleteMessage(widget.channelId, m.id);
      _older.removeWhere((o) => o.id == m.id);
      ref.invalidate(channelMessagesProvider(_key));
    } catch (e) {
      if (mounted) _toast(errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(channelMessagesProvider(_key));

    ref.listen<AsyncValue<MessagePage>>(
      channelMessagesProvider(_key),
      (previous, next) {
        final page = next.value;
        if (page != null) _markRead(page);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(async.value?.channelName ?? 'Channel'),
        actions: [
          if (!widget.mine)
            IconButton(
              tooltip: 'Edit channel',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push(
                  '/admin/announcements/channels/${widget.channelId}/edit',
                );
                ref.invalidate(channelMessagesProvider(_key));
              },
            ),
        ],
      ),
      body: AsyncBody<MessagePage>(
        value: async,
        onRetry: () => ref.invalidate(channelMessagesProvider(_key)),
        builder: _chat,
      ),
    );
  }

  Widget _chat(MessagePage page) {
    final colors = context.appColors;
    final messages = _combined(page.messages);
    final hasMore = _olderHasMore ?? page.hasMore;

    return Column(
      children: [
        Expanded(
          child:
              messages.isEmpty
                  ? const EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No messages yet',
                    message:
                        'Messages in this channel will appear here.',
                  )
                  : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      12,
                    ),
                    itemCount: messages.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (hasMore && i == messages.length) {
                        return Center(
                          child: TextButton(
                            onPressed:
                                _loadingOlder
                                    ? null
                                    : () => _loadOlder(messages),
                            child: Text(
                              _loadingOlder
                                  ? 'Loading...'
                                  : 'Load earlier messages',
                            ),
                          ),
                        );
                      }
                      final m = messages[messages.length - 1 - i];
                      return _Bubble(
                        message: m,
                        onLongPress:
                            (!widget.mine && !m.isDeleted)
                                ? () => _delete(m)
                                : null,
                        onEdit:
                            m.isMine && !m.isDeleted
                                ? () => _edit(m)
                                : null,
                      );
                    },
                  ),
        ),
        if (page.canWrite)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _text,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 4000,
                          buildCounter:
                              (
                                _, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) => null,
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Write a message',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send',
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _attachmentUrl,
                    decoration: const InputDecoration(
                      hintText: 'Image URL (optional)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Only your therapist can write in this channel.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    this.onLongPress,
    this.onEdit,
  });

  final ChannelMessage message;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final text = Theme.of(context).textTheme;
    final m = message;

    final background = m.isMine ? c.hero : c.secondary;
    final foreground = m.isMine ? c.onHero : c.textPrimary;
    final muted = foreground.withValues(alpha: 0.7);

    return Align(
      alignment:
          m.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!m.isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      m.senderRole == 'admin'
                          ? 'Therapist'
                          : (m.senderName ?? 'Member'),
                      style: text.labelMedium?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  m.isDeleted ? 'Message deleted' : m.text,
                  style: text.bodyMedium?.copyWith(
                    color: m.isDeleted ? muted : foreground,
                    fontStyle:
                        m.isDeleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                  ),
                ),
                if (m.attachmentUrl != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(m.attachmentUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        m.attachmentUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stamp(m.createdAt),
                      style: text.labelSmall?.copyWith(color: muted),
                    ),
                    if (m.editedAt != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(edited)',
                        style: text.labelSmall?.copyWith(
                          color: muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (m.isMine &&
                        !m.isDeleted &&
                        onEdit != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onEdit,
                        child: Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
