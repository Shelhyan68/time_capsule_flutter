import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'src/features/auth/data/auth_repository.dart';
import 'src/features/auth/data/magic_link_service.dart';
import 'src/features/auth/presentation/pages/login_page.dart';
import 'src/features/capsule/presentation/pages/dashboard_page.dart';
import 'src/features/user/data/user_service.dart';
import 'src/features/user/domain/models/user_profile.dart';
import 'src/features/user/presentation/pages/profile_setup_page.dart';
import 'src/app_router.dart';
import 'firebase_options.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TimeCapsuleApp());
}

class TimeCapsuleApp extends StatefulWidget {
  const TimeCapsuleApp({super.key});

  @override
  State<TimeCapsuleApp> createState() => _TimeCapsuleAppState();
}

class _TimeCapsuleAppState extends State<TimeCapsuleApp> {
  StreamSubscription? _linkSubscription;
  final _magicLinkService = MagicLinkService();
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isProcessingLink = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    // Gérer le lien initial (app fermée -> ouverte via lien)
    try {
      final uri = await appLinks.getInitialLink();
      final initialLink = uri?.toString();
      if (initialLink != null) {
        debugPrint('Initial app link detected: $initialLink');
        _handleMagicLink(initialLink);
      }
    } catch (e) {
      debugPrint('Erreur initial app link: $e');
    }

    // Gérer les liens entrants (app déjà ouverte)
    _linkSubscription = appLinks.uriLinkStream.listen(
      (Uri? uri) {
        final link = uri?.toString();
        if (link != null) {
          debugPrint('App link stream detected: $link');
          _handleMagicLink(link);
        }
      },
      onError: (err) {
        debugPrint('Erreur app link stream: $err');
      },
    );
  }

  Future<void> _handleMagicLink(String link) async {
    if (_isProcessingLink) return;

    debugPrint('[MagicLink] _handleMagicLink called with link: $link');
    setState(() => _isProcessingLink = true);

    try {
      final userCredential = await _magicLinkService.signInWithMagicLink(link);

      if (userCredential != null) {
        debugPrint(
          '[MagicLink] Connexion réussie via Magic Link: ${userCredential.user?.email}',
        );

        // Afficher un message de succès
        if (mounted && _navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('✅ Connexion réussie !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('[MagicLink] userCredential est null');
      }
    } catch (e) {
      debugPrint('[MagicLink] Erreur lors de la connexion avec Magic Link: $e');

      // Afficher un message d'erreur explicite
      String message = '❌ Erreur de connexion.';
      if (e.toString().contains('Email manquant')) {
        message =
            '❌ Impossible de retrouver votre email. Merci de cliquer sur le lien magique depuis le même appareil.';
      } else if (e.toString().contains('Lien invalide')) {
        message = '❌ Ce lien magique est invalide ou expiré.';
      }
      if (mounted && _navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingLink = false);
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final userService = UserService(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'TimeCapsule',
      theme: ThemeData(primarySwatch: Colors.blue),
      onGenerateRoute: AppRouter.generateRoute,
      home: StreamBuilder<User?>(
        stream: authRepository.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            // Utilisateur connecté, vérifier s'il a un profil
            return StreamBuilder<UserProfile?>(
              stream: userService.getCurrentUserProfileStream(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final hasProfile = profileSnapshot.data != null;
                if (!hasProfile) {
                  return const ProfileSetupPage();
                }

                return const DashboardPage();
              },
            );
          }

          return const LoginPage();
        },
      ),
    );
  }
}
