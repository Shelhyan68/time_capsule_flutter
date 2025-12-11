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

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.brightness,
    required this.twinkleSpeed,
  });
}

class SpacePainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  SpacePainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      // Déplacement vertical (effet de vitesse spatiale)
      star.y = (star.y + star.speed * 0.002) % 1.0;

      // Position en pixels
      final double x = star.x * size.width;
      final double y = star.y * size.height;

      // Effet de scintillement
      final twinkle = sin(animationValue * 2 * pi * star.twinkleSpeed);
      final opacity = (star.brightness + twinkle * 0.3).clamp(0.0, 1.0);

      // Gradient radial pour l'effet de lueur
      final paint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                Color.lerp(
                  Colors.white,
                  Colors.blue.shade200,
                  star.brightness,
                )!.withOpacity(opacity),
                Colors.transparent,
              ],
              stops: const [0.0, 1.0],
            ).createShader(
              Rect.fromCircle(center: Offset(x, y), radius: star.size * 3),
            );

      // Dessiner l'étoile principale
      canvas.drawCircle(Offset(x, y), star.size, paint);

      // Ajouter un petit halo pour les grosses étoiles
      if (star.size > 1.5) {
        final haloPaint = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(x, y), star.size * 2, haloPaint);
      }

      // Traînée lumineuse simplifiée (seulement pour les étoiles très rapides)
      if (star.speed > 0.45) {
        final trailPaint = Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(opacity * 0.3),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromPoints(Offset(x, y - star.size * 3), Offset(x, y)),
              )
          ..strokeWidth = star.size * 0.5
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(Offset(x, y - star.size * 3), Offset(x, y), trailPaint);
      }
    }
  }

  @override
  bool shouldRepaint(SpacePainter oldDelegate) => true;
}
