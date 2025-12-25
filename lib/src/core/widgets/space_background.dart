import 'dart:math';
import 'package:flutter/material.dart';

class SpaceBackground extends StatefulWidget {
  final Widget child;

  const SpaceBackground({super.key, required this.child});

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Star> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Couleurs LED identiques aux bordures
    const ledColors = [
      Color(0xFF42A5F5), // Bleu
      Color(0xFFAB47BC), // Violet
      Color(0xFF69F0AE), // Vert
      Color(0xFFFF6B9D), // Rose
      Color(0xFFFFA726), // Orange
      Color(0xFF00E5FF), // Cyan
    ];

    // Réduire à 50 étoiles pour de meilleures performances
    for (int i = 0; i < 50; i++) {
      _stars.add(
        Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 2 + 0.5,
          speed: _random.nextDouble() * 0.5 + 0.2,
          brightness: _random.nextDouble() * 0.8 + 0.2,
          twinkleSpeed: _random.nextDouble() * 2 + 1,
          color: ledColors[_random.nextInt(ledColors.length)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fond noir de base
        Container(color: const Color(0xFF0A0E1A)),

        // Étoiles animées
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: SpacePainter(
                stars: _stars,
                animationValue: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Contenu par-dessus
        widget.child,
      ],
    );
  }
}

class Star {
  double x;
  double y;
  final double size;
  final double speed;
  final double brightness;
  final double twinkleSpeed;
  final Color color;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.brightness,
    required this.twinkleSpeed,
    required this.color,
  });
}

class SpacePainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  SpacePainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      // Déplacement diagonal (effet étoile filante)
      star.y = (star.y + star.speed * 0.003) % 1.0;
      star.x = (star.x + star.speed * 0.001) % 1.0;

      // Position en pixels
      final double x = star.x * size.width;
      final double y = star.y * size.height;

      // Effet de scintillement
      final twinkle = sin(animationValue * 2 * pi * star.twinkleSpeed);
      final opacity = (star.brightness + twinkle * 0.2).clamp(0.3, 1.0);

      // Longueur de la traînée basée sur la vitesse
      final trailLength = star.size * 15 + (star.speed * 30);

      // Point de départ (haut-gauche) et point d'arrivée (bas-droite)
      final startX = x - trailLength * 0.7;
      final startY = y - trailLength;
      final endX = x;
      final endY = y;

      // Traînée d'étoile filante avec gradient diagonal
      final trailPaint = Paint()
        ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.transparent,
              star.color.withValues(alpha: opacity * 0.3),
              star.color.withValues(alpha: opacity * 0.8),
              star.color.withValues(alpha: opacity),
            ],
            stops: const [0.0, 0.4, 0.8, 1.0],
          ).createShader(
            Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)),
          )
        ..strokeWidth = star.size * 1.2
        ..strokeCap = StrokeCap.round;

      // Dessiner la traînée
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), trailPaint);

      // Point lumineux à l'extrémité (tête de l'étoile filante)
      final headPaint = Paint()
        ..shader = RadialGradient(
            colors: [
              star.color.withValues(alpha: opacity),
              star.color.withValues(alpha: opacity * 0.5),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(endX, endY), radius: star.size * 3),
          );

      canvas.drawCircle(Offset(endX, endY), star.size * 1.5, headPaint);

      // Glow autour du point lumineux
      final glowPaint = Paint()
        ..color = star.color.withValues(alpha: opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(endX, endY), star.size * 2.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(SpacePainter oldDelegate) => true;
}
