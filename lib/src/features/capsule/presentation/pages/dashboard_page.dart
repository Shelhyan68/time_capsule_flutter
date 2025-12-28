import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/src/features/auth/data/auth_repository.dart';
import '/src/features/capsule/data/capsule_service.dart';
import '/src/features/capsule/domain/models/capsule_model.dart';
import '/src/features/capsule/presentation/widgets/countdown_timer.dart';
import '/src/features/capsule/presentation/widgets/animated_lock_icon.dart';
import '/src/features/capsule/presentation/widgets/empty_capsule_state.dart';
import '/src/features/user/data/user_service.dart';
import '/src/features/user/domain/models/user_profile.dart';
import '/src/core/widgets/space_background.dart';
import '/src/core/widgets/animated_led_border.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final capsuleService = CapsuleService(
      firestore: FirebaseFirestore.instance,
    );
    final userService = UserService(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    final theme = Theme.of(context);

    return SpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Flux temporel',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Mon profil',
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Quitter le flux',
              onPressed: () async {
                try {
                  await authRepository.signOut();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedLedBorder(
                borderRadius: 28,
                borderWidth: 2,
                glowIntensity: 10,
                animationDuration: const Duration(seconds: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    child: Column(
                      children: [
                        StreamBuilder<UserProfile?>(
                          stream: userService.getCurrentUserProfileStream(),
                          builder: (context, profileSnapshot) {
                            final profile = profileSnapshot.data;
                            final greeting = profile != null
                                ? 'Bienvenue ${profile.firstName}'
                                : 'Bienvenue dans ta capsule';

                            return Text(
                              greeting,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Le temps s’écoule, tes souvenirs restent',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: StreamBuilder<List<CapsuleModel>>(
                            stream: capsuleService.getCapsules(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Erreur: ${snapshot.error}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                );
                              }
                              final capsules = snapshot.data ?? [];
                              if (capsules.isEmpty) {
                                return const EmptyCapsuleState();
                              }

                              return ListView.builder(
                                itemCount: capsules.length,
                                itemBuilder: (context, index) {
                                  final capsule = capsules[index];
                                  final now = DateTime.now();
                                  final isUnlocked = now.isAfter(
                                    capsule.openDate,
                                  );

                                  return Dismissible(
                                    key: Key(capsule.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text(
                                              'Supprimer la capsule ?',
                                            ),
                                            content: Text(
                                              'Voulez-vous vraiment supprimer "${capsule.title}" ?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text('Supprimer'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    onDismissed: (direction) async {
                                      try {
                                        await capsuleService.deleteCapsule(
                                          capsule.id,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Capsule supprimée',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Erreur: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: AnimatedLedBorder(
                                        borderRadius: 12,
                                        borderWidth: 1.5,
                                        glowIntensity: 8,
                                        animationDuration: const Duration(seconds: 3),
                                        child: Card(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          margin: EdgeInsets.zero,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                AnimatedLockIcon(
                                                  isUnlocked: isUnlocked,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              capsule.title,
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          if (capsule.capsuleType != null)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: capsule.capsuleType == 'received'
                                                                    ? Colors.green.withOpacity(0.2)
                                                                    : Colors.blue.withOpacity(0.2),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                border: Border.all(
                                                                  color: capsule.capsuleType == 'received'
                                                                      ? Colors.green.withOpacity(0.5)
                                                                      : Colors.blue.withOpacity(0.5),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    capsule.capsuleType == 'received'
                                                                        ? Icons.card_giftcard
                                                                        : Icons.email,
                                                                    size: 14,
                                                                    color: capsule.capsuleType == 'received'
                                                                        ? Colors.green.shade200
                                                                        : Colors.blue.shade200,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Text(
                                                                    capsule.capsuleType == 'received'
                                                                        ? 'Reçue'
                                                                        : 'Envoyée',
                                                                    style: TextStyle(
                                                                      color: capsule.capsuleType == 'received'
                                                                          ? Colors.green.shade200
                                                                          : Colors.blue.shade200,
                                                                      fontSize:
                                                                          11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (capsule.capsuleType == 'received' && capsule.senderName != null)
                                                        Text(
                                                          'De: ${capsule.senderName}',
                                                          style: TextStyle(
                                                            color: Colors.green.shade200,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      if (capsule.capsuleType == 'received' && capsule.senderName != null)
                                                        const SizedBox(height: 2),
                                                      Text(
                                                        'Ouverture: ${capsule.openDate.day}/${capsule.openDate.month}/${capsule.openDate.year}',
                                                        style: const TextStyle(
                                                          color: Colors.white60,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isUnlocked)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.arrow_forward,
                                                      color: Colors.white,
                                                    ),
                                                    onPressed: () {
                                                      Navigator.pushNamed(
                                                        context,
                                                        '/open',
                                                        arguments: capsule,
                                                      );
                                                    },
                                                  ),
                                              ],
                                            ),
                                            if (!isUnlocked) ...[
                                              const SizedBox(height: 12),
                                              CountdownTimer(
                                                targetDate: capsule.openDate,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    ),
                                    ),
                                  );
                                },
                              );
                            },
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/create');
          },
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle capsule'),
        ),
      ),
    );
  }
}
