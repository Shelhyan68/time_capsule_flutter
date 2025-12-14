import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';

import 'firebase_options.dart';
import 'src/app_router.dart';
import 'src/features/auth/data/auth_repository.dart';
import 'src/features/auth/presentation/pages/login_page.dart';
import 'src/features/capsule/presentation/pages/dashboard_page.dart';
import 'src/features/user/data/user_service.dart';
import 'src/features/user/domain/models/user_profile.dart';
import 'src/features/user/presentation/pages/profile_setup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TimeCapsuleApp());
}

/// Application principale Time Capsule
class TimeCapsuleApp extends StatefulWidget {
  const TimeCapsuleApp({super.key});

  @override
  State<TimeCapsuleApp> createState() => _TimeCapsuleAppState();
}

class _TimeCapsuleAppState extends State<TimeCapsuleApp>
    with WidgetsBindingObserver {
  // Services
  final _authRepository = AuthRepository();
  late final UserService _userService;

  // Deep Links
  late final AppLinks _appLinks;
  StreamSubscription? _linkSubscription;

  // State
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isProcessingLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userService = UserService(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// Rafraîchit l'UI quand l'app revient au premier plan
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isProcessingLink) {
      debugPrint('🔄 App resumed - refreshing UI');
      setState(() {});
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // DEEP LINKS (Magic Link)
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Lien initial (app fermée -> ouverte via lien)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('📩 Initial link: $initialUri');
        _handleDeepLink(initialUri.toString());
      }
    } catch (e) {
      debugPrint('❌ Error getting initial link: $e');
    }

    // Liens entrants (app déjà ouverte)
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        debugPrint('📩 Link stream: $uri');
        _handleDeepLink(uri.toString());
      }
    }, onError: (err) => debugPrint('❌ Link stream error: $err'));
  }

  Future<void> _handleDeepLink(String link) async {
    if (_isProcessingLink) {
      debugPrint('⚠️ Already processing a link, skipping');
      return;
    }

    debugPrint('🔗 Processing deep link: $link');

    // Extraire le lien Firebase si c'est un custom scheme
    String actualLink = link;
    if (link.startsWith('timecapsule://')) {
      try {
        final uri = Uri.parse(link);
        final encodedLink = uri.queryParameters['link'];
        if (encodedLink != null) {
          actualLink = Uri.decodeComponent(encodedLink);
          debugPrint('🔗 Extracted Firebase link: $actualLink');
        } else {
          return;
        }
      } catch (e) {
        debugPrint('❌ Error parsing custom scheme: $e');
        return;
      }
    }

    // Vérifier si c'est un lien Firebase Auth
    if (!actualLink.contains('firebaseapp.com') &&
        !actualLink.contains('web.app')) {
      debugPrint('⚠️ Not a Firebase link, ignoring');
      return;
    }

    _isProcessingLink = true;
    if (mounted) setState(() {});

    try {
      final userCredential = await _authRepository.signInWithMagicLink(
        actualLink,
      );
      if (userCredential != null) {
        debugPrint(
          '✅ Magic link sign-in successful: ${userCredential.user?.email}',
        );
      }
    } catch (e) {
      debugPrint('❌ Magic link sign-in error: $e');
      _showError('Erreur de connexion: ${e.toString()}');
    } finally {
      _isProcessingLink = false;
      if (mounted) setState(() {});
    }
  }

  void _showError(String message) {
    if (!mounted || _navigatorKey.currentContext == null) return;
    ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Time Capsule',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      onGenerateRoute: AppRouter.generateRoute,
      home: _buildHome(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF0B0F1A),
    );
  }

  Widget _buildHome() {
    // Loading pendant le traitement du magic link
    if (_isProcessingLink) {
      return const _LoadingScreen(message: 'Connexion en cours...');
    }

    return StreamBuilder<User?>(
      stream: _authRepository.authStateChanges(),
      builder: (context, authSnapshot) {
        debugPrint(
          '🔄 Auth state: ${authSnapshot.data?.email ?? "non connecté"}',
        );

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // Non connecté -> Login
        if (!authSnapshot.hasData) {
          return const LoginPage();
        }

        // Connecté -> Vérifier profil
        return StreamBuilder<UserProfile?>(
          stream: _userService.getCurrentUserProfileStream(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            // Pas de profil -> Setup
            if (profileSnapshot.data == null) {
              return const ProfileSetupPage();
            }

            // Profil OK -> Dashboard
            return const DashboardPage();
          },
        );
      },
    );
  }
}

/// Écran de chargement réutilisable
class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({this.message = 'Chargement...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
