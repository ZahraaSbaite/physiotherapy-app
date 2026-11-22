import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// A section title with a terracotta accent bar + optional "View all" action.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.showAccent = true,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showAccent;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showAccent) ...[
            // 👈 the terracotta spark
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: c.highlight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleLarge),
                if (subtitle != null)
                  Text(subtitle!, style: text.bodySmall),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              // inherits terracotta from textButtonTheme
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
