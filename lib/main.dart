import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late AppLinks _appLinks;
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
    _appLinks = AppLinks();

    // Gérer le lien initial (app fermée -> ouverte via lien)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Initial link detected: $initialUri');
        _handleMagicLink(initialUri.toString());
      }
    } catch (e) {
      debugPrint('Erreur initial link: $e');
    }

    // Gérer les liens entrants (app déjà ouverte)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          debugPrint('Link stream detected: $uri');
          _handleMagicLink(uri.toString());
        }
      },
      onError: (err) {
        debugPrint('Erreur link stream: $err');
      },
    );
  }

  Future<void> _handleMagicLink(String link) async {
    if (_isProcessingLink) return;

    debugPrint('🔗 [DeepLink] Lien reçu: $link');

    String actualLink = link;

    // Si c'est un custom scheme, extraire le lien Firebase du paramètre
    if (link.startsWith('timecapsule://')) {
      debugPrint('📱 [DeepLink] Custom scheme détecté');
      try {
        final uri = Uri.parse(link);
        final encodedLink = uri.queryParameters['link'];
        if (encodedLink != null) {
          actualLink = Uri.decodeComponent(encodedLink);
          debugPrint('🔗 [DeepLink] Lien Firebase extrait: $actualLink');
        } else {
          debugPrint(
            '⚠️ [DeepLink] Paramètre "link" manquant dans le custom scheme',
          );
          return;
        }
      } catch (e) {
        debugPrint('❌ [DeepLink] Erreur parsing custom scheme: $e');
        return;
      }
    }

    // Vérifier si c'est un lien Firebase Auth
    if (!actualLink.contains('firebaseapp.com') &&
        !actualLink.contains('web.app')) {
      debugPrint('⚠️ [DeepLink] Ce n\'est pas un lien Firebase, ignoré');
      return;
    }

    setState(() => _isProcessingLink = true);

    try {
      debugPrint('🔄 [DeepLink] Tentative de connexion avec le magic link...');
      final userCredential = await _magicLinkService.signInWithMagicLink(
        actualLink,
      );

      if (userCredential != null) {
        debugPrint(
          '✅ [DeepLink] Connexion réussie: ${userCredential.user?.email}',
        );

        // Faire un retour arrière automatique pour fermer la page du navigateur
        // et revenir à l'app (qui affichera le dashboard ou profile)
        await Future.delayed(const Duration(milliseconds: 200));
        SystemNavigator.pop();
      }
    } catch (e) {
      debugPrint('❌ [DeepLink] Erreur lors de la connexion: $e');

      // Afficher un message d'erreur
      if (mounted && _navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur de connexion: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
          // Afficher un loader pendant le traitement du magic link
          if (_isProcessingLink) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connexion en cours...'),
                  ],
                ),
              ),
            );
          }

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
