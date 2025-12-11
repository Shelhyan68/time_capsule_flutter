import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '/src/core/widgets/space_background.dart';
import '../../domain/models/capsule_model.dart';
import '../widgets/exploding_particles.dart';
import '../widgets/opened_capsule_content.dart';

class OpenCapsulePage extends StatefulWidget {
  final CapsuleModel capsule;
  const OpenCapsulePage({super.key, required this.capsule});

  @override
  State<OpenCapsulePage> createState() => _OpenCapsulePageState();
}

class _OpenCapsulePageState extends State<OpenCapsulePage>
    with TickerProviderStateMixin {
  late AnimationController _lockController;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotationAnim;
  late AnimationController _particlesController;
  bool _isOpened = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _isOpened = now.isAfter(widget.capsule.openDate);

    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _lockController, curve: Curves.easeOutBack),
    );

    _rotationAnim = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _lockController, curve: Curves.easeOut));

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (_isOpened) _openCapsule();
  }

  @override
  void dispose() {
    _lockController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  void _openCapsule() async {
    if (!_isOpened) {
      setState(() => _isOpened = true);
      await _lockController.forward();
      _particlesController.forward();
    } else {
      _particlesController.forward();
    }
  }

  Future<void> _deleteCapsule() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la capsule ?'),
        content: const Text(
          'Cette action est irréversible et supprimera tous les médias associés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      // Supprimer les médias de Firebase Storage
      for (final url in widget.capsule.mediaUrls) {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      }

      // Supprimer la capsule de Firestore
      await FirebaseFirestore.instance
          .collection('capsules')
          .doc(widget.capsule.id)
          .delete();

      if (!mounted) return;

      Navigator.pop(context); // Retour à la liste après suppression
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Capsule temporelle',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: _isDeleting ? null : _deleteCapsule,
              icon: _isDeleting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.delete),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _openCapsule,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _particlesController,
                                builder: (_, child) {
                                  return CustomPaint(
                                    painter: ExplodingParticles(
                                      progress: _particlesController.value,
                                    ),
                                    size: const Size(120, 120),
                                  );
                                },
                              ),
                              AnimatedBuilder(
                                animation: _lockController,
                                builder: (_, child) {
                                  return Transform.rotate(
                                    angle: _rotationAnim.value * 2 * pi,
                                    child: Transform.scale(
                                      scale: _scaleAnim.value,
                                      child: Icon(
                                        _isOpened
                                            ? Icons.lock_open
                                            : Icons.lock_outline,
                                        size: 64,
                                        color: _isOpened
                                            ? Colors.greenAccent
                                            : Colors.orangeAccent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.capsule.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ouverture prévue le '
                          '${widget.capsule.openDate.day}/${widget.capsule.openDate.month}/${widget.capsule.openDate.year}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: AnimatedOpacity(
                            opacity: _isOpened ? 1 : 0,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeIn,
                            child: _isOpened
                                ? OpenedCapsuleContent(capsule: widget.capsule)
                                : const Center(
                                    child: Text(
                                      'Capsule verrouillée',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
