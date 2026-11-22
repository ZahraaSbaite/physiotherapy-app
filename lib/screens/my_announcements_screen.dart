import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/announcement.dart';
import '../services/announcement_repository.dart';
import '../widgets/announcement_widgets.dart';
import '../widgets/app_states.dart';
import '../widgets/page_helpers.dart';

/// Patient: broadcasts and channels from the therapist.
class MyAnnouncementsScreen extends ConsumerWidget {
  const MyAnnouncementsScreen({super.key});

  Future<void> _openBroadcast(BuildContext context, WidgetRef ref, Broadcast b) async {
    final repo = ref.read(announcementRepositoryProvider);
    if (!b.isRead) {
      // Fire and forget: opening the message matters more than the read mark
      repo.markBroadcastRead(b.id).then((_) => ref.invalidate(myBroadcastsProvider)).catchError((_) {});
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BroadcastSheet(broadcast: b),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcasts = ref.watch(myBroadcastsProvider);
    final channels = ref.watch(myChannelsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Announcements'),
          bottom: const TabBar(tabs: [Tab(text: 'Messages'), Tab(text: 'Channels')]),
        ),
        body: TabBarView(
          children: [
            RefreshPage(
              onRefresh: () async => ref.refresh(myBroadcastsProvider.future),
              child: AsyncBody<List<Broadcast>>(
                value: broadcasts,
                onRetry: () => ref.invalidate(myBroadcastsProvider),
                builder: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'No messages yet',
                      message: 'Messages from your therapist will appear here.',
                    );
                  }
                  return Column(
                    children: [
                      for (final b in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BroadcastCard(
                            broadcast: b,
                            onTap: () => _openBroadcast(context, ref, b),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            RefreshPage(
              onRefresh: () async => ref.refresh(myChannelsProvider.future),
              child: AsyncBody<List<Channel>>(
                value: channels,
                onRetry: () => ref.invalidate(myChannelsProvider),
                builder: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No channels yet',
                      message: 'Channels you are added to will appear here.',
                    );
                  }
                  return Column(
                    children: [
                      for (final c in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ChannelCard(
                            channel: c,
                            onTap: () async {
                              await context.push('/patient/announcements/channels/${c.id}');
                              ref.invalidate(myChannelsProvider);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BroadcastSheet extends StatelessWidget {
  const _BroadcastSheet({required this.broadcast});
  final Broadcast broadcast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final b = broadcast;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if ((b.title ?? '').isNotEmpty) Text(b.title!, style: text.titleLarge),
          Text(stamp(b.sentAt), style: text.bodySmall?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 12),
          Text(b.text, style: text.bodyLarge),
        ],
      ),
    );
  }
}
