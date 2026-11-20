import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// A rounded square with an icon inside, used as the leading element of rows
/// and as the brand mark.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? c.secondary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: foreground ?? c.primary),
    );
  }
}

/// A small rounded label, for example a role or a "Soon" tag.
class AppPill extends StatelessWidget {
  const AppPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: c.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The content of a list row: icon tile, title, optional subtitle and an
/// optional trailing widget. Put it inside an [AppCard].
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Red styling for actions such as logging out.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        IconTile(
          icon: icon,
          background: destructive ? c.errorSoft : null,
          foreground: destructive ? c.error : null,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.titleMedium?.copyWith(
                  color: destructive ? c.error : null,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: text.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}

/// The chevron shown at the end of a row that opens another screen.
class TileChevron extends StatelessWidget {
  const TileChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      color: context.appColors.textSecondary,
    );
  }
}
