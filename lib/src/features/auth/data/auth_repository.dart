import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Repository centralisé pour toutes les opérations d'authentification.
/// Supporte : Magic Link, Google Sign-In, Apple Sign-In (iOS).
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Configuration Magic Link
  static const String _continueUrl = 'https://time-capsule-5ecb5.web.app';
  static const String _androidPackageName = 'com.simacreation.timecapsule';
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
  /// Crée automatiquement le profil utilisateur avec les données Google
  Future<UserCredential> signInWithGoogle() async {
    UserCredential userCredential;

    // Web
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
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

      userCredential = await _auth.signInWithCredential(credential);
    }

    final user = userCredential.user;

    if (user != null) {
      // Vérifier si le profil existe déjà
      final profileDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!profileDoc.exists) {
        // Extraire prénom et nom depuis displayName
        String firstName = '';
        String lastName = '';

        if (user.displayName != null) {
          final nameParts = user.displayName!.split(' ');
          firstName = nameParts.isNotEmpty ? nameParts.first : '';
          lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        }

        if (firstName.isEmpty) {
          firstName = 'Utilisateur';
        }

        // Créer le profil automatiquement
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'birthDate': null,
          'createdAt': Timestamp.now(),
          'updatedAt': null,
        });

        debugPrint('✅ Profil Google créé automatiquement: $firstName $lastName');
      }
    }

    return userCredential;
  }

  // ─────────────────────────────────────────────────────────────────────
  // APPLE SIGN-IN (iOS uniquement)
  // ─────────────────────────────────────────────────────────────────────

  /// Connexion avec Apple (iOS uniquement)
  /// Crée automatiquement le profil utilisateur avec les données Apple
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

    debugPrint('🍎 Apple Credential reçu:');
    debugPrint('   - givenName: ${appleCredential.givenName}');
    debugPrint('   - familyName: ${appleCredential.familyName}');
    debugPrint('   - email: ${appleCredential.email}');

    // Sauvegarder le nom si fourni (première connexion uniquement)
    final prefs = await SharedPreferences.getInstance();
    if (appleCredential.givenName != null && appleCredential.givenName!.isNotEmpty) {
      await prefs.setString('apple_given_name', appleCredential.givenName!);
      debugPrint('✅ Prénom Apple sauvegardé: ${appleCredential.givenName}');
    }
    if (appleCredential.familyName != null && appleCredential.familyName!.isNotEmpty) {
      await prefs.setString('apple_family_name', appleCredential.familyName!);
      debugPrint('✅ Nom Apple sauvegardé: ${appleCredential.familyName}');
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    final user = userCredential.user;

    if (user != null) {
      // Vérifier si le profil existe déjà
      final profileDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!profileDoc.exists) {
        // Récupérer le nom depuis Apple ou depuis SharedPreferences
        String firstName = appleCredential.givenName ??
                          prefs.getString('apple_given_name') ?? '';
        String lastName = appleCredential.familyName ??
                         prefs.getString('apple_family_name') ?? '';

        debugPrint('📝 Nom récupéré - Prénom: "$firstName", Nom: "$lastName"');

        // Si Apple n'a pas fourni le nom, essayer avec displayName de Firebase
        if (firstName.isEmpty && lastName.isEmpty && user.displayName != null) {
          final nameParts = user.displayName!.split(' ');
          firstName = nameParts.isNotEmpty ? nameParts.first : '';
          lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          debugPrint('📝 Nom depuis displayName - Prénom: "$firstName", Nom: "$lastName"');
        }

        // Si toujours vide, utiliser "Utilisateur" par défaut
        if (firstName.isEmpty) {
          firstName = 'Utilisateur';
          debugPrint('⚠️ Aucun nom trouvé, utilisation du défaut: "Utilisateur"');
        }

        // Créer le profil automatiquement
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': user.email ?? appleCredential.email ?? '',
          'photoUrl': user.photoURL,
          'birthDate': null,
          'createdAt': Timestamp.now(),
          'updatedAt': null,
        });

        debugPrint('✅ Profil Apple créé automatiquement: $firstName $lastName');
      } else {
        debugPrint('ℹ️ Profil existant trouvé pour ${user.uid}');
      }
    }

    return userCredential;
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
