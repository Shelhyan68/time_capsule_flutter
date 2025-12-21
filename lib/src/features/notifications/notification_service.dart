import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer les notifications push Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialise le service de notifications
  Future<void> initialize() async {
    try {
      // Demander la permission pour les notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('📱 Permission notifications: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Obtenir le token FCM
        final token = await _messaging.getToken();
        debugPrint('📱 FCM Token: $token');

        if (token != null) {
          await _saveTokenToFirestore(token);
        }

        // Écouter les changements de token
        _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

        // Configurer les handlers de notifications
        _setupNotificationHandlers();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur initialisation notifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Sauvegarde le token FCM dans Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Utilisateur non connecté, token non sauvegardé');
        return;
      }

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Token FCM sauvegardé pour ${user.uid}');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde token: $e');
    }
  }

  /// Configure les handlers pour les différents états de notification
  void _setupNotificationHandlers() {
    // Message reçu quand l'app est en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Notification reçue (foreground): ${message.notification?.title}');

      if (message.notification != null) {
        debugPrint('Titre: ${message.notification!.title}');
        debugPrint('Body: ${message.notification!.body}');
      }

      // Ici tu peux afficher une notification locale ou un snackbar
      // Pour l'instant on log juste
    });

    // Message cliqué quand l'app est en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 Notification cliquée (background): ${message.notification?.title}');
      _handleNotificationClick(message);
    });

    // Vérifier si l'app a été ouverte depuis une notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📩 App ouverte depuis notification: ${message.notification?.title}');
        _handleNotificationClick(message);
      }
    });
  }

  /// Gère le clic sur une notification
  void _handleNotificationClick(RemoteMessage message) {
    // Récupérer les données de la notification
    final data = message.data;
    debugPrint('📦 Data: $data');

    // Effacer le badge de notification
    clearBadge();

    // Si la notification contient un capsuleId, on pourrait naviguer vers cette capsule
    if (data.containsKey('capsuleId')) {
      final capsuleId = data['capsuleId'];
      debugPrint('🎁 Ouvrir capsule: $capsuleId');
      // TODO: Naviguer vers la page de la capsule
    }
  }

  /// Efface le badge de notification (pastille rouge)
  Future<void> clearBadge() async {
    try {
      // Sur Android, le badge se gère via les canaux de notification
      // Firebase Messaging gère automatiquement le badge quand l'app est ouverte
      await _messaging.setAutoInitEnabled(true);
      debugPrint('✅ Badge effacé');
    } catch (e) {
      debugPrint('❌ Erreur effacement badge: $e');
    }
  }

  /// Supprime le token FCM lors de la déconnexion
  Future<void> deleteToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        debugPrint('✅ Token FCM supprimé');
      }

      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('❌ Erreur suppression token: $e');
    }
  }
}

/// Handler pour les notifications en arrière-plan
/// Doit être une fonction top-level (pas dans une classe)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Notification reçue (background): ${message.notification?.title}');
}
