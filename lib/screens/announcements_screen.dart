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

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState
    extends ConsumerState<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onBroadcasts = _tabs.index == 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Broadcasts'),
            Tab(text: 'Channels'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(
            onBroadcasts
                ? '/admin/announcements/broadcasts/new'
                : '/admin/announcements/channels/new',
          );
          ref.invalidate(broadcastsProvider);
          ref.invalidate(channelsProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(onBroadcasts ? 'New broadcast' : 'New channel'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_BroadcastList(), _ChannelList()],
      ),
    );
  }
}

class _BroadcastList extends ConsumerWidget {
  const _BroadcastList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(broadcastsProvider);
    return RefreshPage(
      onRefresh: () async => ref.refresh(broadcastsProvider.future),
      child: AsyncBody<List<Broadcast>>(
        value: async,
        onRetry: () => ref.invalidate(broadcastsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No broadcasts yet',
              message:
                  'Send a message to all your patients or to a few of them.',
            );
          }
          return Column(
            children: [
              for (final b in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BroadcastCard(
                    broadcast: b,
                    forAdmin: true,
                    onTap:
                        () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => _BroadcastSheet(id: b.id),
                        ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BroadcastSheet extends ConsumerWidget {
  const _BroadcastSheet({required this.id});
  final String id;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete announcement?'),
            content: const Text('Patients will no longer see it.'),
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
          .deleteBroadcast(id);
      ref.invalidate(broadcastsProvider);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final async = ref.watch(broadcastProvider(id));

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: AsyncBody<Broadcast>(
        value: async,
        onRetry: () => ref.invalidate(broadcastProvider(id)),
        builder:
            (b) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.title ?? 'Broadcast',
                        style: text.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(
                          '/admin/announcements/broadcasts/new?id=${b.id}',
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  stamp(b.sentAt),
                  style: text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(b.text, style: text.bodyLarge),
                if (b.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      b.imageUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SectionHeader('Read by'),
                Text(
                  '${b.readCount} of ${b.recipientCount} patients',
                  style: text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final r in b.recipients)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(r.name),
                    trailing: Icon(
                      r.read
                          ? Icons.done_all_rounded
                          : Icons.schedule_rounded,
                      color:
                          r.read
                              ? colors.primary
                              : colors.textSecondary,
                      size: 20,
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _delete(context, ref),
                  child: const Text(
                    'Delete announcement',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _ChannelList extends ConsumerWidget {
  const _ChannelList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(channelsProvider);
    return RefreshPage(
      onRefresh: () async => ref.refresh(channelsProvider.future),
      child: AsyncBody<List<Channel>>(
        value: async,
        onRetry: () => ref.invalidate(channelsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No channels yet',
              message:
                  'A channel is a group your patients can follow, for example "Knee exercises".',
            );
          }
          return Column(
            children: [
              for (final c in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChannelCard(
                    channel: c,
                    forAdmin: true,
                    onTap: () async {
                      await context.push(
                        '/admin/announcements/channels/${c.id}',
                      );
                      ref.invalidate(channelsProvider);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
