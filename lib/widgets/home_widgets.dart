import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'user_avatar.dart';
import 'nav_shell.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Greeting, today's date and the user's avatar, at the top of a home screen.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.name});

  final String name;

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final date = '${_weekdays[now.weekday - 1]}, ${now.day} '
        '${_months[now.month - 1]}';
    final firstName = name.trim().split(' ').first;
    final greeting = _greeting(now.hour);

    return Row(
      children: [
        IconButton(
          tooltip: 'Open navigation menu',
          onPressed: NavShell.openDrawer,
          icon: const Icon(Icons.menu_rounded),
          style: IconButton.styleFrom(
            backgroundColor: context.appColors.secondary,
            foregroundColor: context.appColors.primary,
            fixedSize: const Size(44, 44),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: text.labelMedium),
              const SizedBox(height: 4),
              Text(
                firstName.isEmpty ? greeting : '$greeting, $firstName',
                style: text.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        UserAvatar(name: name, size: 48),
      ],
    );
  }
}

/// A heading above a group of cards.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: context.appColors.textPrimary),
        ),
      ),
    );
  }
}
