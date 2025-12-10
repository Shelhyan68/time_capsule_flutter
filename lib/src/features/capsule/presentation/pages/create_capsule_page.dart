import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CreateCapsulePage extends StatefulWidget {
  const CreateCapsulePage({Key? key}) : super(key: key);

  @override
  State<CreateCapsulePage> createState() => _CreateCapsulePageState();
}

class _CreateCapsulePageState extends State<CreateCapsulePage> {
  final _titleController = TextEditingController();
  DateTime? _openDate;
  final List<File> _mediaFiles = [];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _openDate = picked);
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _mediaFiles.add(File(picked.path)));
  }

  Future<void> _pickVideo() async {
    final picked = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _mediaFiles.add(File(picked.path)));
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() => _mediaFiles.add(File(result.files.first.path!)));
    }
  }

  Future<void> _saveCapsule() async {
    if (_titleController.text.isEmpty || _openDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir le titre et la date')),
      );
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Uploader les fichiers vers Firebase Storage
      final List<String> mediaUrls = [];
      for (final file in _mediaFiles) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final storageRef = FirebaseStorage.instance.ref().child(
          'capsules/$fileName',
        );
        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();
        mediaUrls.add(downloadUrl);
      }

      // 2. Créer le document dans Firestore
      await FirebaseFirestore.instance.collection('capsules').add({
        'title': _titleController.text,
        'openDate': Timestamp.fromDate(_openDate!),
        'mediaUrls': mediaUrls,
        'createdAt': Timestamp.now(),
      });

      // Fermer le dialogue de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capsule créée avec succès !')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Fermer le dialogue de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une capsule')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la capsule',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _openDate != null
                        ? 'Date d’ouverture : ${_openDate!.day}/${_openDate!.month}/${_openDate!.year}'
                        : 'Aucune date sélectionnée',
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Choisir la date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Photo'),
                  onPressed: _pickImage,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.videocam),
                  label: const Text('Vidéo'),
                  onPressed: _pickVideo,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.insert_drive_file),
                  label: const Text('Document'),
                  onPressed: _pickDocument,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _mediaFiles.length,
                itemBuilder: (_, index) {
                  final file = _mediaFiles[index];
                  return ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(file.path.split('/').last),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveCapsule,
              child: const Text('Enregistrer la capsule'),
            ),
          ],
        ),
      ),
    );
  }
}
