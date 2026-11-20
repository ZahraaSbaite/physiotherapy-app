import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Fades a widget in with a small upward slide when it first appears.
///
/// Give items in a list increasing [index] values and they settle one after
/// the other. Does nothing when the device asks to reduce animations.
class AppearAnimation extends StatelessWidget {
  const AppearAnimation({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium + Duration(milliseconds: 80 * index),
      curve: AppMotion.curve,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
    );
  }
}
