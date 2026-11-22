import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/announcement.dart';
import '../utils/formatters.dart';
import 'app_card.dart';
import 'app_tile.dart';

/// "14:05" for today, "21/11/2026 14:05" for other days.
String stamp(DateTime d) {
  final now = DateTime.now();
  final today = d.year == now.year && d.month == now.month && d.day == now.day;
  return today ? fmtTime(d) : '${fmtDate(d)} ${fmtTime(d)}';
}

/// A broadcast in a list. Therapists see who it reached; patients see an unread dot.
class BroadcastCard extends StatelessWidget {
  const BroadcastCard({super.key, required this.broadcast, required this.onTap, this.forAdmin = false});

  final Broadcast broadcast;
  final VoidCallback onTap;
  final bool forAdmin;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;
    final b = broadcast;
    final unread = !forAdmin && !b.isRead;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (unread)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: colors.highlight, shape: BoxShape.circle),
                ),
              Expanded(
                child: Text(
                  (b.title ?? '').trim().isNotEmpty ? b.title!.trim() : 'Announcement',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
              ),
              Text(stamp(b.sentAt),
                  style: text.bodySmall?.copyWith(color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(b.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
          if (forAdmin) ...[
            const SizedBox(height: 8),
            Text(
              '${b.sentToAll ? 'Sent to everyone' : 'Sent to selected patients'}'
              ' · read by ${b.readCount} of ${b.recipientCount}',
              style: text.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// A channel in a list, with its last message and unread count.
class ChannelCard extends StatelessWidget {
  const ChannelCard({super.key, required this.channel, required this.onTap, this.forAdmin = false});

  final Channel channel;
  final VoidCallback onTap;
  final bool forAdmin;

  @override
  Widget build(BuildContext context) {
    final c = channel;
    final subtitle = (c.lastMessageText ?? '').isNotEmpty
        ? c.lastMessageText!
        : (c.description ?? '').isNotEmpty
            ? c.description!
            : forAdmin
                ? '${c.memberCount} members'
                : 'No messages yet';

    return AppCard(
      onTap: onTap,
      child: AppTile(
        icon: Icons.forum_outlined,
        title: c.name,
        subtitle: subtitle,
        trailing: c.unreadCount > 0
            ? AppPill('${c.unreadCount} new')
            : Icon(Icons.chevron_right_rounded, color: context.appColors.textSecondary),
      ),
    );
  }
}
