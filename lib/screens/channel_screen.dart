import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/announcement.dart';
import '../services/announcement_repository.dart';
import '../utils/formatters.dart';
import '../widgets/announcement_widgets.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// A channel's messages. [mine] is true for patients (their own endpoints).
/// New messages arrive when the screen refreshes itself (every 20 seconds) or on send.
class ChannelScreen extends ConsumerStatefulWidget {
  const ChannelScreen({super.key, required this.channelId, required this.mine});

  final String channelId;
  final bool mine;

  @override
  ConsumerState<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends ConsumerState<ChannelScreen> {
  final _text = TextEditingController();
  final List<ChannelMessage> _older = [];
  Timer? _poll;
  bool _loadingOlder = false;
  bool? _olderHasMore;
  bool _sending = false;
  String? _pendingId;
  String? _pendingText;
  String? _lastReadId;

  ChannelKey get _key => (id: widget.channelId, mine: widget.mine);

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && !_sending) ref.invalidate(channelMessagesProvider(_key));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  List<ChannelMessage> _combined(List<ChannelMessage> page) {
    final byId = <String, ChannelMessage>{for (final m in [..._older, ...page]) m.id: m};
    return byId.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _markRead(MessagePage page) async {
    if (page.messages.isEmpty || page.messages.last.id == _lastReadId) return;
    _lastReadId = page.messages.last.id;
    try {
      await ref.read(announcementRepositoryProvider).markChannelRead(_key);
      if (!mounted) return;
      ref.invalidate(widget.mine ? myChannelsProvider : channelsProvider);
    } catch (_) {
      // Not important enough to bother the user
    }
  }

  Future<void> _loadOlder(List<ChannelMessage> current) async {
    if (current.isEmpty || _loadingOlder) return;
    setState(() => _loadingOlder = true);
    try {
      final page = await ref
          .read(announcementRepositoryProvider)
          .messages(_key, before: current.first.createdAt);
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

    // Retrying the same text reuses the id, so the server never stores it twice
    if (_pendingText != text) {
      _pendingId = newClientMessageId();
      _pendingText = text;
    }

    setState(() => _sending = true);
    try {
      await ref.read(announcementRepositoryProvider).sendMessage(_key, text, _pendingId!);
      _text.clear();
      _pendingId = null;
      _pendingText = null;
      ref.invalidate(channelMessagesProvider(_key));
    } catch (e) {
      if (mounted) _toast(errorText(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(ChannelMessage m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('Members will see that a message was deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(announcementRepositoryProvider).deleteMessage(widget.channelId, m.id);
      _older.removeWhere((o) => o.id == m.id);
      ref.invalidate(channelMessagesProvider(_key));
    } catch (e) {
      if (mounted) _toast(errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(channelMessagesProvider(_key));

    ref.listen<AsyncValue<MessagePage>>(channelMessagesProvider(_key), (previous, next) {
      final page = next.value;
      if (page != null) _markRead(page);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(async.value?.channelName ?? 'Channel'),
        actions: [
          if (!widget.mine)
            IconButton(
              tooltip: 'Edit channel',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push('/admin/announcements/channels/${widget.channelId}/edit');
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
          child: messages.isEmpty
              ? const EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No messages yet',
                  message: 'Messages in this channel will appear here.',
                )
              : ListView.builder(
                  reverse: true, // newest at the bottom
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (hasMore && i == messages.length) {
                      return Center(
                        child: TextButton(
                          onPressed: _loadingOlder ? null : () => _loadOlder(messages),
                          child: Text(_loadingOlder ? 'Loading...' : 'Load earlier messages'),
                        ),
                      );
                    }
                    final m = messages[messages.length - 1 - i];
                    return _Bubble(
                      message: m,
                      onLongPress: (!widget.mine && !m.isDeleted) ? () => _delete(m) : null,
                    );
                  },
                ),
        ),
        if (page.canWrite)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 4000,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Write a message'),
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
            ),
          )
        else
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Only your therapist can write in this channel.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onLongPress});

  final ChannelMessage message;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final text = Theme.of(context).textTheme;
    final m = message;

    final background = m.isMine ? c.hero : c.secondary;
    final foreground = m.isMine ? c.onHero : c.textPrimary;
    final muted = foreground.withValues(alpha: 0.7);

    return Align(
      alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      m.fromTherapist ? 'Therapist' : (m.senderName ?? 'Member'),
                      style: text.labelMedium?.copyWith(color: muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                Text(
                  m.isDeleted ? 'Message deleted' : m.text,
                  style: text.bodyMedium?.copyWith(
                    color: m.isDeleted ? muted : foreground,
                    fontStyle: m.isDeleted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(stamp(m.createdAt), style: text.labelSmall?.copyWith(color: muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
