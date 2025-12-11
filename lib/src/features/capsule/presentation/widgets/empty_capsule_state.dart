import 'package:flutter/material.dart';

class EmptyCapsuleState extends StatelessWidget {
  const EmptyCapsuleState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.all_inbox, size: 64, color: Colors.white.withOpacity(0.6)),
        const SizedBox(height: 16),
        const Text(
          'Aucune capsule pour le moment',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Crée ta première capsule\ntemporelle',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
  }
}
