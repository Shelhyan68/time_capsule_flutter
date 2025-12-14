import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class MagicLinkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // URL de la page de redirection qui ouvrira l'app via custom scheme
  static const String _continueUrl = 'https://time-capsule-5ecb5.web.app/auth';
  static const String _androidPackageName = 'com.example.time_capsule';

  /// Envoie un magic link à l'email fourni
  Future<void> sendMagicLink(String email) async {
    // Configuration du lien
    final actionCodeSettings = ActionCodeSettings(
      url: _continueUrl,
      handleCodeInApp: true, // Important !
      androidPackageName: _androidPackageName, // Votre package Android
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: 'com.example.timeCapsule', // Votre bundle iOS
    );

    try {
      // Envoyer le magic link
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      // Sauvegarder l'email localement pour la vérification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emailForSignIn', email);

      print('Magic link envoyé à $email');
    } catch (e) {
      print('Erreur lors de l\'envoi du magic link: $e');
      rethrow;
    }
  }

  /// Vérifie si le lien est un magic link valide et connecte l'utilisateur
  Future<UserCredential?> signInWithMagicLink(String emailLink) async {
    try {
      debugPrint('[MagicLink] signInWithMagicLink: emailLink = $emailLink');
      // Vérifier si c'est un lien de connexion valide
      final isValid = _auth.isSignInWithEmailLink(emailLink);
      debugPrint('[MagicLink] isSignInWithEmailLink: $isValid');
      if (!isValid) {
        throw Exception('Lien invalide');
      }

      // Récupérer l'email sauvegardé
      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('emailForSignIn');
      debugPrint('[MagicLink] emailForSignIn in SharedPreferences: $email');

      if (email == null) {
        // Si l'email n'est pas sauvegardé, demander à l'utilisateur
        throw Exception('Email manquant');
      }

      // Se connecter avec le lien
      final userCredential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      debugPrint(
        '[MagicLink] signInWithEmailLink OK: ${userCredential.user?.email}',
      );

      // Nettoyer l'email sauvegardé
      await prefs.remove('emailForSignIn');

      return userCredential;
    } catch (e) {
      debugPrint('[MagicLink] Erreur lors de la connexion avec magic link: $e');
      rethrow;
    }
  }

  /// Vérifie l'état de connexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
