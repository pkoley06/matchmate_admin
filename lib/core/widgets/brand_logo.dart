import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The MateEazy mark: a house roof over two arched doors ("two doors, one
/// home"). Drawn from the same path as the mobile app's logo asset.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 32, this.color = BrandColors.coral, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size * 1.018),
    painter: _MarkPainter(color),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Source artboard is 35.5 x 36.124.
    final s = size.width / 35.5;
    canvas.scale(s);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roof = Path()
      ..moveTo(1.75, 17.0407)
      ..lineTo(17.75, 2.374)
      ..lineTo(33.75, 17.0407);
    final left = Path()
      ..moveTo(6.67309, 34.374)
      ..lineTo(6.67309, 19.7073)
      ..cubicTo(6.67309, 10.374, 17.75, 10.374, 17.75, 19.7073);
    final mid = Path()
      ..moveTo(17.75, 19.7073)
      ..lineTo(17.75, 33.0407);
    final right = Path()
      ..moveTo(17.75, 19.7073)
      ..cubicTo(17.75, 10.374, 28.8269, 10.374, 28.8269, 19.7073)
      ..lineTo(28.8269, 34.374);

    for (final p in [roof, left, mid, right]) {
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}

/// Mark + "MateEazy" wordmark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    this.height = 32,
    this.textColor,
    this.showWordmark = true,
    super.key,
  });

  final double height;
  final Color? textColor;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final ink = textColor ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: height),
        if (showWordmark) ...[
          SizedBox(width: height * 0.32),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Mate', style: TextStyle(color: ink)),
                const TextSpan(
                  text: 'Eazy',
                  style: TextStyle(color: BrandColors.coral),
                ),
              ],
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: height * 0.72,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}
