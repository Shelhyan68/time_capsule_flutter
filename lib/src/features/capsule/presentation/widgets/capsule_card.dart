import 'package:flutter/material.dart';
import '../../domain/models/capsule_model.dart';

class CapsuleCard extends StatelessWidget {
  final CapsuleModel capsule;
  final VoidCallback onTap;

  const CapsuleCard({super.key, required this.capsule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = now.isAfter(capsule.openDate) ? 'Ouverte' : 'À venir';

    return Card(
      child: ListTile(
        title: Text(capsule.title),
        subtitle: Text(
          'Ouverture: ${capsule.openDate.toLocal().toShortDateString()}',
        ),
        trailing: Text(status),
        onTap: onTap,
      ),
    );
  }
}

extension DateHelpers on DateTime {
  String toShortDateString() {
    return "${day}/${month}/${year}";
  }
}
