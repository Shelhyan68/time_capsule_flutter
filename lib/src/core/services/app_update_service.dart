import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer la vérification des mises à jour de l'application
class AppUpdateService {
  final FirebaseFirestore _firestore;

  AppUpdateService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Vérifie si une mise à jour est disponible
  /// Retourne un objet UpdateInfo ou null si pas de mise à jour
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Récupérer les infos de l'app actuelle
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      debugPrint('📱 Version actuelle: ${packageInfo.version}+$currentBuildNumber');

      // Récupérer les infos de version depuis Firestore
      final doc = await _firestore.collection('app_config').doc('version').get();

      if (!doc.exists) {
        debugPrint('⚠️ Document de version non trouvé dans Firestore');
        return null;
      }

      final data = doc.data()!;
      final latestBuildNumber = data['latestBuildNumber'] as int;
      final minBuildNumber = data['minBuildNumber'] as int;
      final latestVersion = data['latestVersion'] as String;
      final updateMessage = data['updateMessage'] as String?;
      final updateUrl = data['updateUrl'] as String?;

      debugPrint('🔄 Dernière version: $latestVersion+$latestBuildNumber');
      debugPrint('⚡ Version minimum: $minBuildNumber');

      // Vérifier si une mise à jour est requise ou recommandée
      if (currentBuildNumber < minBuildNumber) {
        // Mise à jour obligatoire
        return UpdateInfo(
          isRequired: true,
          latestVersion: latestVersion,
          latestBuildNumber: latestBuildNumber,
          currentVersion: packageInfo.version,
          currentBuildNumber: currentBuildNumber,
          message: updateMessage ?? 'Une mise à jour obligatoire est disponible.',
          updateUrl: updateUrl,
        );
      } else if (currentBuildNumber < latestBuildNumber) {
        // Mise à jour optionnelle
        return UpdateInfo(
          isRequired: false,
          latestVersion: latestVersion,
          latestBuildNumber: latestBuildNumber,
          currentVersion: packageInfo.version,
          currentBuildNumber: currentBuildNumber,
          message: updateMessage ?? 'Une nouvelle version est disponible !',
          updateUrl: updateUrl,
        );
      }

      // Pas de mise à jour
      debugPrint('✅ Application à jour');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de mise à jour: $e');
      return null;
    }
  }
}

/// Informations sur la mise à jour disponible
class UpdateInfo {
  final bool isRequired; // true = obligatoire, false = optionnelle
  final String latestVersion;
  final int latestBuildNumber;
  final String currentVersion;
  final int currentBuildNumber;
  final String message;
  final String? updateUrl;

  UpdateInfo({
    required this.isRequired,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.message,
    this.updateUrl,
  });
}
