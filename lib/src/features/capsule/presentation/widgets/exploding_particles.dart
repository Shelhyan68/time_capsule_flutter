import 'dart:math';
import 'package:flutter/material.dart';

class ExplodingParticles extends CustomPainter {
  final double progress;
  final int particleCount;
  final Random _random = Random();

  ExplodingParticles({required this.progress, this.particleCount = 30});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < particleCount; i++) {
      final angle = 2 * pi * (i / particleCount) + _random.nextDouble();
      final radius = size.width * 0.5 * progress;
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);
      final hue = (_random.nextDouble() * 360).toInt();

      final paint = Paint()
        ..color = HSVColor.fromAHSV(
          1 - progress,
          hue.toDouble(),
          0.7,
          1.0,
        ).toColor()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(dx, dy), 4 * (1 - progress) + 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ExplodingParticles oldDelegate) => true;
}
