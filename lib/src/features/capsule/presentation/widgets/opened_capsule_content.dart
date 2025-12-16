import 'package:flutter/material.dart';
import '../../domain/models/capsule_model.dart';

class OpenedCapsuleContent extends StatelessWidget {
  final CapsuleModel capsule;

  const OpenedCapsuleContent({super.key, required this.capsule});

  @override
  Widget build(BuildContext context) {
    final List<Widget> contentWidgets = [];

    // Lettre / texte
    if (capsule.letter != null && capsule.letter!.isNotEmpty) {
      contentWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              capsule.letter!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    // Médias
    if (capsule.mediaUrls.isEmpty) {
      contentWidgets.add(
        const Center(
          child: Text(
            'Aucun média dans cette capsule',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    } else {
      contentWidgets.addAll(
        capsule.mediaUrls.map((url) {
          // Vérifier si c'est une image (Firebase Storage URLs contiennent le nom du fichier encodé)
          final urlLower = url.toLowerCase();
          final isImage =
              urlLower.contains('.jpg') ||
              urlLower.contains('.jpeg') ||
              urlLower.contains('.png') ||
              urlLower.contains('.gif') ||
              urlLower.contains('.webp');

          if (isImage) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    );
                  },
                  cacheWidth: 800, // Optimisation mémoire
                ),
              ),
            );
          }

          return ListTile(
            leading: const Icon(Icons.insert_drive_file, color: Colors.white70),
            title: Text(
              url.split('/').last,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }),
      );
    }

    return ListView(children: contentWidgets);
  }
}
