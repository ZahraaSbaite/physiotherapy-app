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

/// Patient: their broadcast inbox and their channels.
class MyAnnouncementsScreen extends ConsumerWidget {
  const MyAnnouncementsScreen({super.key});

  Future<void> _openBroadcast(
    BuildContext context,
    WidgetRef ref,
    Broadcast b,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BroadcastSheet(broadcast: b),
    );
    // Mark as read after viewing
    if (!b.isRead) {
      try {
        await ref
            .read(announcementRepositoryProvider)
            .markBroadcastRead(b.id);
      } catch (_) {}
    }
    ref.invalidate(myBroadcastsProvider);
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
          bottom: const TabBar(
            tabs: [Tab(text: 'Broadcasts'), Tab(text: 'Channels')],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshPage(
              onRefresh:
                  () async =>
                      ref.refresh(myBroadcastsProvider.future),
              child: AsyncBody<List<Broadcast>>(
                value: broadcasts,
                onRetry: () => ref.invalidate(myBroadcastsProvider),
                builder: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'Nothing yet',
                      message:
                          'Announcements from your therapist appear here.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final b = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BroadcastCard(
                          broadcast: b,
                          forAdmin: false,
                          onTap:
                              () => _openBroadcast(context, ref, b),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            RefreshPage(
              onRefresh:
                  () async => ref.refresh(myChannelsProvider.future),
              child: AsyncBody<List<Channel>>(
                value: channels,
                onRetry: () => ref.invalidate(myChannelsProvider),
                builder: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No channels',
                      message:
                          'You are not a member of any channel yet.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final c = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ChannelCard(
                          channel: c,
                          forAdmin: false,
                          onTap:
                              () => context.push(
                                '/patient/announcements/channels/${c.id}',
                              ),
                        ),
                      );
                    },
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
      height: MediaQuery.of(context).size.height * 0.7,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if ((b.title ?? '').isNotEmpty)
            Text(b.title!, style: text.titleLarge),
          Text(
            stamp(b.sentAt),
            style: text.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(b.text, style: text.bodyLarge),
          if ((b.imageUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                b.imageUrl!,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
