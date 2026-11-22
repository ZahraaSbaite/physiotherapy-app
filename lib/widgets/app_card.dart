import 'package:flutter/material.dart';
import 'package:physio_app/core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.isHighlighted = false, // NEW: Makes the card "pop"
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool isHighlighted;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final content = Padding(
      padding: widget.padding,
      child: widget.child,
    );
    final onTap = widget.onTap;

    if (onTap == null) {
      return Card(
        elevation: widget.isHighlighted ? 4 : 0,
        shadowColor:
            widget.isHighlighted
                ? colors.highlight.withValues(alpha: 0.25)
                : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color:
                widget.isHighlighted
                    ? colors.highlight
                    : colors.border,
            width: widget.isHighlighted ? 1.5 : 1,
          ),
        ),
        child: content,
      );
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: _pressed && !reduceMotion ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Card(
        elevation: widget.isHighlighted ? 4 : 0,
        shadowColor:
            widget.isHighlighted
                ? colors.highlight.withValues(alpha: 0.25)
                : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color:
                widget.isHighlighted
                    ? colors.highlight
                    : colors.border,
            width: widget.isHighlighted ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          onHighlightChanged:
              (value) => setState(() => _pressed = value),
          child: content,
        ),
      ),
    );
  }
}
