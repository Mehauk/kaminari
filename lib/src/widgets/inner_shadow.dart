import 'package:flutter/material.dart';

class InnerShadow extends StatelessWidget {
  final Widget child;
  final List<BoxShadow>? shadows;
  final BorderRadius borderRadius;

  const InnerShadow({
    super.key,
    required this.child,
    this.shadows,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (shadows == null || shadows!.isEmpty) return child;

    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        foregroundPainter: _InnerShadowPainter(shadows!, borderRadius),
        child: child,
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  final List<BoxShadow> shadows;
  final BorderRadius borderRadius;

  _InnerShadowPainter(this.shadows, this.borderRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    for (final shadow in shadows) {
      final shadowRect = rect.inflate(shadow.spreadRadius);
      final shadowRRect = borderRadius.toRRect(shadowRect);
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma);

      canvas.save();
      canvas.clipRRect(rrect);
      final shadowPath = Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(shadowRRect)
        ..addRect(shadowRect.inflate(shadow.blurRadius + shadow.spreadRadius));
      canvas.drawPath(shadowPath, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_InnerShadowPainter oldDelegate) => true;
}
