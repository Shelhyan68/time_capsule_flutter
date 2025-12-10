import 'package:flutter/material.dart';
import '../models/capsule_model.dart';

class OpenCapsulePage extends StatelessWidget {
  final CapsuleModel capsule;

  const OpenCapsulePage({Key? key, required this.capsule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOpen = now.isAfter(capsule.openDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Ouvrir Capsule')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capsule.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ouverture : ${capsule.openDate.day}/${capsule.openDate.month}/${capsule.openDate.year}',
            ),
            const SizedBox(height: 8),
            Text('Statut : ${isOpen ? "Ouverte" : "À venir"}'),
            const SizedBox(height: 16),
            if (!isOpen)
              const Text('Cette capsule n’est pas encore disponible.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: capsule.mediaUrls.length,
                  itemBuilder: (context, index) {
                    final url = capsule.mediaUrls[index];
                    final extension = url.split('.').last;

                    if (extension == 'jpg' || extension == 'png') {
                      return Image.network(url);
                    } else if (extension == 'mp4') {
                      return const Text('Vidéo non supportée pour le moment');
                    } else {
                      return Text('Fichier: $url');
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
