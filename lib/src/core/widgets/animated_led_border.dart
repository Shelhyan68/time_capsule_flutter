import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget qui ajoute une bordure LED animée avec changement de couleur
/// qui tourne autour de l'élément enfant
class AnimatedLedBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final Duration animationDuration;
  final List<Color> colors;
  final double glowIntensity;

  const AnimatedLedBorder({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = 16.0,
    this.animationDuration = const Duration(seconds: 3),
    this.glowIntensity = 8.0,
    this.colors = const [
      Color(0xFF42A5F5), // Bleu
      Color(0xFFAB47BC), // Violet
      Color(0xFF69F0AE), // Vert
      Color(0xFFFF6B9D), // Rose
      Color(0xFFFFA726), // Orange
      Color(0xFF00E5FF), // Cyan
    ],
  });

  @override
  State<AnimatedLedBorder> createState() => _AnimatedLedBorderState();
}

class _AnimatedLedBorderState extends State<AnimatedLedBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LedBorderPainter(
            animationValue: _controller.value,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
            colors: widget.colors,
            glowIntensity: widget.glowIntensity,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _LedBorderPainter extends CustomPainter {
  final double animationValue;
  final double borderWidth;
  final double borderRadius;
  final List<Color> colors;
  final double glowIntensity;

  _LedBorderPainter({
    required this.animationValue,
    required this.borderWidth,
    required this.borderRadius,
    required this.colors,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // Créer un gradient qui tourne
    final double rotationAngle = animationValue * 2 * math.pi;

    // Calculer les couleurs avec interpolation
    final int colorCount = colors.length;
    final double colorPosition = animationValue * colorCount;
    final int currentColorIndex = colorPosition.floor() % colorCount;
    final int nextColorIndex = (currentColorIndex + 1) % colorCount;
    final double colorLerp = colorPosition - colorPosition.floor();

    final Color startColor = Color.lerp(
      colors[currentColorIndex],
      colors[nextColorIndex],
      colorLerp,
    )!;

    final Color endColor = Color.lerp(
      colors[(currentColorIndex + 2) % colorCount],
      colors[(currentColorIndex + 3) % colorCount],
      colorLerp,
    )!;

    // Créer le gradient avec rotation
    final gradient = SweepGradient(
      colors: [
        startColor,
        endColor,
        startColor.withValues(alpha: 0.3),
        endColor.withValues(alpha: 0.3),
        startColor,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      transform: GradientRotation(rotationAngle),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Ajouter un glow fin mais très vif
    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowIntensity);

    // Dessiner le glow puis la bordure principale fine et vive
    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_LedBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
