import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_update_service.dart';

/// Dialog pour informer l'utilisateur d'une mise à jour disponible
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !updateInfo.isRequired, // Empêche de fermer si obligatoire
      child: AlertDialog(
        backgroundColor: const Color(0xFF1A1F2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              updateInfo.isRequired ? Icons.warning : Icons.info,
              color: updateInfo.isRequired ? Colors.orange : Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                updateInfo.isRequired
                    ? 'Mise à jour requise'
                    : 'Mise à jour disponible',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              updateInfo.message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Version actuelle',
                    '${updateInfo.currentVersion} (${updateInfo.currentBuildNumber})',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Nouvelle version',
                    '${updateInfo.latestVersion} (${updateInfo.latestBuildNumber})',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!updateInfo.isRequired)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Plus tard',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ElevatedButton(
            onPressed: () => _openUpdateUrl(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: updateInfo.isRequired ? Colors.orange : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Mettre à jour',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _openUpdateUrl(BuildContext context) async {
    final urlString = updateInfo.updateUrl ??
        'https://play.google.com/store/apps/details?id=com.simacreation.timecapsule';

    final url = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (context.mounted && !updateInfo.isRequired) {
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le lien de mise à jour'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
