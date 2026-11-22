import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/announcement.dart';
import '../services/announcement_repository.dart';
import 'app_card.dart';
import 'app_tile.dart';

/// Patient home: the latest announcement and how many are unread.
class AnnouncementsPreview extends ConsumerWidget {
  const AnnouncementsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcasts = ref.watch(myBroadcastsProvider);
    final channels = ref.watch(myChannelsProvider);

    final list = broadcasts.value ?? const <Broadcast>[];
    final chs = channels.value ?? const <Channel>[];
    final unread = list.where((b) => !b.isRead).length +
        chs.fold<int>(0, (sum, c) => sum + c.unreadCount);

    final String subtitle;
    if (broadcasts.hasError && channels.hasError) {
      subtitle = "Couldn't load announcements. Tap to retry.";
    } else if (list.isNotEmpty) {
      subtitle = list.first.headline;
    } else if (broadcasts.isLoading) {
      subtitle = 'Loading...';
    } else {
      subtitle = 'Nothing new from your therapist.';
    }

    return AppCard(
      onTap: () async {
        await context.push('/patient/announcements');
        ref.invalidate(myBroadcastsProvider);
        ref.invalidate(myChannelsProvider);
      },
      child: AppTile(
        icon: Icons.campaign_outlined,
        title: 'Announcements',
        subtitle: subtitle,
        trailing: unread > 0
            ? AppPill('$unread new')
            : Icon(Icons.chevron_right_rounded, color: context.appColors.textSecondary),
      ),
    );
  }
}

/// Therapist home: entry to announcements, with unread channel replies.
class AdminAnnouncementsCard extends ConsumerWidget {
  const AdminAnnouncementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelsProvider).value ?? const <Channel>[];
    final unread = channels.fold<int>(0, (sum, c) => sum + c.unreadCount);

    return AppCard(
      onTap: () async {
        await context.push('/admin/announcements');
        ref.invalidate(channelsProvider);
      },
      child: AppTile(
        icon: Icons.campaign_outlined,
        title: 'Announcements',
        subtitle: 'Broadcasts and channels for your patients.',
        trailing: unread > 0
            ? AppPill('$unread new')
            : Icon(Icons.chevron_right_rounded, color: context.appColors.textSecondary),
      ),
    );
  }
}
