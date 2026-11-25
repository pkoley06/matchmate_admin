import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The MateEazy mark: the smiling house (coral walls, plum outline and face),
/// the same drawing as the website favicon and the app's launcher icon.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: const _SmilingHousePainter(),
  );
}

class _SmilingHousePainter extends CustomPainter {
  const _SmilingHousePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Source artboard is 680 x 680 (mateeazy_website/favicon.svg).
    canvas.scale(size.width / 680);

    final house = Path()
      ..moveTo(340, 18)
      ..lineTo(660, 288)
      ..lineTo(620, 288)
      ..lineTo(620, 664)
      ..lineTo(60, 664)
      ..lineTo(60, 288)
      ..lineTo(20, 288)
      ..close();
    canvas.drawPath(house, Paint()..color = BrandColors.coral);
    canvas.drawPath(
      house,
      Paint()
        ..color = BrandColors.plum
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeJoin = StrokeJoin.miter,
    );

    final ink = Paint()..color = BrandColors.plum;
    for (final cx in const [210.0, 318.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, 392), width: 38, height: 56),
        ink,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(226, 466)
        ..quadraticBezierTo(282, 572, 338, 466),
      Paint()
        ..color = BrandColors.plum
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SmilingHousePainter old) => false;
}

/// Mark + "MateEazy" wordmark, with an optional "ADMIN" tag underneath.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    this.height = 32,
    this.textColor,
    this.showWordmark = true,
    this.showAdminTag = false,
    super.key,
  });

  final double height;
  final Color? textColor;
  final bool showWordmark;
  final bool showAdminTag;

  @override
  Widget build(BuildContext context) {
    final ink = textColor ?? Theme.of(context).colorScheme.onSurface;
    final theme = Theme.of(context);
    final wordmark = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Mate', style: TextStyle(color: ink)),
          const TextSpan(
            text: 'Eazy',
            style: TextStyle(color: BrandColors.coral),
          ),
        ],
      ),
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: height * 0.66,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1,
      ),
    );
    return Semantics(
      label: showAdminTag ? 'MateEazy Admin' : 'MateEazy',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: height),
          if (showWordmark) ...[
            SizedBox(width: height * 0.3),
            showAdminTag
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      wordmark,
                      SizedBox(height: height * 0.1),
                      Text(
                        'ADMIN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ink.withValues(alpha: 0.7),
                          fontSize: (height * 0.28).clamp(9, 12),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                          height: 1,
                        ),
                      ),
                    ],
                  )
                : wordmark,
          ],
        ],
      ),
    );
  }
}
