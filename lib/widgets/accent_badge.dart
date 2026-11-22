import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A small terracotta pill: "3 new", "Today", "Due now".
class AccentBadge extends StatelessWidget {
  const AccentBadge({
    super.key,
    required this.label,
    this.icon,
    this.soft = false,
  });

  final String label;
  final IconData? icon;

  /// true  → soft terracotta background + terracotta text (subtle)
  /// false → solid terracotta background + white text (loud)
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bg = soft ? c.highlightSoft : c.highlight;
    final fg = soft ? c.highlight : c.onHighlight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border:
            soft
                ? Border.all(
                  color: c.highlight.withValues(alpha: 0.3),
                )
                : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
