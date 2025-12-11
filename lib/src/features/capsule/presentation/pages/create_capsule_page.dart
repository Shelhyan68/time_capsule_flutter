import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/src/features/auth/data/auth_repository.dart';
import '/src/features/capsule/domain/models/capsule_model.dart';
import '/src/features/capsule/data/email_service.dart';
import '/src/features/user/data/user_service.dart';
import '/src/core/widgets/space_background.dart';

class CreateCapsulePage extends StatefulWidget {
  const CreateCapsulePage({super.key});

  @override
  State<CreateCapsulePage> createState() => _CreateCapsulePageState();
}

class _CreateCapsulePageState extends State<CreateCapsulePage> {
  final _titleController = TextEditingController();
  final _letterController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientEmailController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _openDate;
  final List<File> _mediaFiles = [];

  bool _isLoading = false;
  bool _hasRecipient = false;

  @override
  void dispose() {
    _titleController.dispose();
    _letterController.dispose();
    _recipientNameController.dispose();
    _recipientEmailController.dispose();
    super.dispose();
  }

  // ─── Date ──────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _openDate = picked);
    }
  }

  // ─── Médias ────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _mediaFiles.add(File(picked.path)));
  }

  Future<void> _pickVideo() async {
    final picked = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _mediaFiles.add(File(picked.path)));
  }

  // ─── Sauvegarde ────────────────────────────────────────
  Future<void> _saveCapsule() async {
    if (_titleController.text.isEmpty || _openDate == null) {
      _showMessage('Titre et date requis');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> mediaUrls = [];

      for (final file in _mediaFiles) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

        final ref = FirebaseStorage.instance.ref().child('capsules/$fileName');

        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        mediaUrls.add(url);
      }

      final capsule = CapsuleModel(
        id: '', // Firestore va générer l'id
        title: _titleController.text,
        openDate: _openDate!,
        mediaUrls: mediaUrls,
        letter: _letterController.text.isEmpty ? null : _letterController.text,
        recipientName: _hasRecipient && _recipientNameController.text.isNotEmpty
            ? _recipientNameController.text
            : null,
        recipientEmail:
            _hasRecipient && _recipientEmailController.text.isNotEmpty
            ? _recipientEmailController.text
            : null,
      );

      final docRef = await FirebaseFirestore.instance
          .collection('capsules')
          .add(capsule.toFirestore());

      // Planifier l'email si un destinataire est défini
      if (_hasRecipient &&
          _recipientEmailController.text.isNotEmpty &&
          _recipientNameController.text.isNotEmpty) {
        try {
          final userService = UserService(
            firestore: FirebaseFirestore.instance,
            auth: FirebaseAuth.instance,
          );
          final currentProfile = await userService.getCurrentUserProfile();
          final senderName = currentProfile?.fullName ?? 'Un ami';

          final emailService = EmailService(
            firestore: FirebaseFirestore.instance,
          );
          await emailService.scheduleEmail(
            capsuleId: docRef.id,
            recipientEmail: _recipientEmailController.text.trim(),
            recipientName: _recipientNameController.text.trim(),
            capsuleTitle: _titleController.text,
            sendDate: _openDate!,
            senderName: senderName,
          );

          // Déterminer si l'email part immédiatement ou plus tard
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final targetDate = DateTime(
            _openDate!.year,
            _openDate!.month,
            _openDate!.day,
          );
          final isToday =
              targetDate.isBefore(today) || targetDate.isAtSameMomentAs(today);

          if (mounted) {
            _showMessage(
              isToday
                  ? 'Capsule scellée ! Email envoyé à ${_recipientNameController.text}'
                  : 'Capsule scellée ! Email programmé pour ${_recipientNameController.text}',
            );
          }
        } catch (e) {
          // L'email n'a pas pu être planifié mais la capsule est créée
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Capsule créée mais erreur email: ${e.toString()}',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else if (mounted) {
        _showMessage('Capsule scellée dans le temps');
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── UI ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authRepository = AuthRepository();

    return SpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Crée une capsule temporelle',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Quitter le flux',
              onPressed: () async {
                try {
                  authRepository.logout();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sceller une capsule',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Conserve un fragment du présent pour le futur',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Titre
                            TextField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                'Titre de la capsule',
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Lettre / texte
                            TextField(
                              controller: _letterController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 5,
                              decoration: _inputDecoration(
                                'Écris une lettre ou un texte',
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Date
                            OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                _openDate == null
                                    ? "Choisir la date d'ouverture"
                                    : 'Ouverture : ${_openDate!.day}/${_openDate!.month}/${_openDate!.year}',
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Section destinataire
                            CheckboxListTile(
                              value: _hasRecipient,
                              onChanged: (value) {
                                setState(() => _hasRecipient = value ?? false);
                              },
                              title: const Text(
                                'Envoyer par email à un destinataire',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: const Text(
                                'La capsule sera envoyée automatiquement à la date d\'ouverture',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                              activeColor: Colors.blue,
                            ),

                            if (_hasRecipient) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _recipientNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  'Prénom du destinataire',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _recipientEmailController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                  'Email du destinataire',
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Médias
                            Wrap(
                              spacing: 12,
                              children: [
                                _mediaButton(Icons.photo, 'Photo', _pickImage),
                                _mediaButton(
                                  Icons.videocam,
                                  'Vidéo',
                                  _pickVideo,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Liste médias
                            if (_mediaFiles.isNotEmpty) ...[
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _mediaFiles.length,
                                itemBuilder: (_, index) {
                                  final file = _mediaFiles[index];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.attach_file,
                                      color: Colors.white70,
                                    ),
                                    title: Text(
                                      file.path.split('/').last,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Bouton sauvegarde
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _saveCapsule,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Sceller la capsule'),
                              ),
                            ),
                          ],
                        ), // Column
                      ), // Container
                    ), // BackdropFilter
                  ), // ClipRRect
                ), // ConstrainedBox
              ), // Center
            ), // Padding
          ), // SingleChildScrollView
        ), // SafeArea
      ), // Scaffold
    ); // SpaceBackground
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _mediaButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
