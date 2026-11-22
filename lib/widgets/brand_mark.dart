import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The iPhysio logo: a rounded square with a lowercase "i" whose dot is the
/// app's warm highlight color.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      label: 'iPhysio',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BrandPainter(
            background: c.hero,
            stemColor: c.onHero,
            dotColor: c.highlight,
          ),
        ),
      ),
    );
  }
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter({
    required this.background,
    required this.stemColor,
    required this.dotColor,
  });

  final Color background;
  final Color stemColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * 0.3)),
      Paint()..color = background,
    );

    final stemWidth = w * 0.14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.60),
          width: stemWidth,
          height: h * 0.34,
        ),
        Radius.circular(stemWidth / 2),
      ),
      Paint()..color = stemColor,
    );

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.27),
      w * 0.095,
      Paint()..color = dotColor,
    );
  }

  @override
  bool shouldRepaint(_BrandPainter old) =>
      old.background != background ||
      old.stemColor != stemColor ||
      old.dotColor != dotColor;
}
