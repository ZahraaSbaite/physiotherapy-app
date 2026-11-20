import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A bordered card with consistent padding.
///
/// The look (surface color, border, radius) comes from the theme. When
/// [onTap] is set the card is tappable and gives a subtle press feedback.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: widget.padding, child: widget.child);
    final onTap = widget.onTap;
    if (onTap == null) return Card(child: content);

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: _pressed && !reduceMotion ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Card(
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: content,
        ),
      ),
    );
  }
}
