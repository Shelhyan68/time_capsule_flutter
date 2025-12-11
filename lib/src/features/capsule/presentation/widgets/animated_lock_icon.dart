import 'package:flutter/material.dart';

class AnimatedLockIcon extends StatefulWidget {
  final bool isUnlocked;

  const AnimatedLockIcon({super.key, required this.isUnlocked});

  @override
  State<AnimatedLockIcon> createState() => _AnimatedLockIconState();
}

class _AnimatedLockIconState extends State<AnimatedLockIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Icon(
        widget.isUnlocked ? Icons.lock_open : Icons.lock,
        color: widget.isUnlocked ? Colors.greenAccent : Colors.orangeAccent,
      ),
    );
  }
}
