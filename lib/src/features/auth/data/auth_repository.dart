import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Repository centralisé pour toutes les opérations d'authentification.
/// Supporte : Magic Link, Google Sign-In, Apple Sign-In (iOS).
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Configuration Magic Link
  static const String _continueUrl = 'https://time-capsule-5ecb5.web.app';
  static const String _androidPackageName = 'com.example.time_capsule';
  static const String _iosBundleId = 'com.example.timeCapsule';

  // ─────────────────────────────────────────────────────────────────────
  // MAGIC LINK
  // ─────────────────────────────────────────────────────────────────────

  /// Envoie un magic link à l'email fourni
  Future<void> sendMagicLink(String email) async {
    final actionCodeSettings = ActionCodeSettings(
      url: _continueUrl,
      handleCodeInApp: true,
      androidPackageName: _androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: _iosBundleId,
    );

    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );

    // Sauvegarder l'email pour la vérification ultérieure
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emailForSignIn', email);

    debugPrint('✉️ Magic link envoyé à $email');
  }

  /// Vérifie et connecte l'utilisateur via magic link
  Future<UserCredential?> signInWithMagicLink(String emailLink) async {
    debugPrint('[MagicLink] Tentative de connexion...');

    if (!_auth.isSignInWithEmailLink(emailLink)) {
      throw AuthException('Lien de connexion invalide');
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('emailForSignIn');

    if (email == null) {
      throw AuthException('Email non trouvé. Veuillez réessayer.');
    }

    final userCredential = await _auth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );

    // Nettoyer l'email sauvegardé
    await prefs.remove('emailForSignIn');

    debugPrint('✅ Connexion Magic Link réussie: ${userCredential.user?.email}');
    return userCredential;
  }

  // ─────────────────────────────────────────────────────────────────────
  // GOOGLE SIGN-IN
  // ─────────────────────────────────────────────────────────────────────

  /// Connexion avec Google
  Future<UserCredential> signInWithGoogle() async {
    // Web
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      return await _auth.signInWithPopup(googleProvider);
    }

    // Mobile (Android/iOS)
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Connexion Google annulée');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // ─────────────────────────────────────────────────────────────────────
  // APPLE SIGN-IN (iOS uniquement)
  // ─────────────────────────────────────────────────────────────────────

  /// Connexion avec Apple (iOS uniquement)
  Future<UserCredential> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw AuthException('Apple Sign-In disponible uniquement sur iOS/macOS');
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    return await _auth.signInWithCredential(oauthCredential);
  }

  // ─────────────────────────────────────────────────────────────────────
  // ÉTAT & DÉCONNEXION
  // ─────────────────────────────────────────────────────────────────────

  /// Stream des changements d'état d'authentification
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Utilisateur actuel
  User? get currentUser => _auth.currentUser;

  /// Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    debugPrint('👋 Utilisateur déconnecté');
  }
}

/// Exception personnalisée pour l'authentification
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
