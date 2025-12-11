import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  final FirebaseFirestore _firestore;

  EmailService({required FirebaseFirestore firestore}) : _firestore = firestore;

  /// Planifie l'envoi d'un email pour une capsule
  /// Si la date d'envoi est aujourd'hui ou dans le passé, l'email sera envoyé immédiatement
  /// Sinon, crée un document dans 'scheduled_emails' pour un envoi ultérieur via Cloud Functions
  Future<void> scheduleEmail({
    required String capsuleId,
    required String recipientEmail,
    required String recipientName,
    required String capsuleTitle,
    required DateTime sendDate,
    required String senderName,
  }) async {
    try {
      // Normaliser les dates pour la comparaison (ignorer l'heure)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDate = DateTime(sendDate.year, sendDate.month, sendDate.day);

      // Si la date d'envoi est aujourd'hui ou passée, envoyer immédiatement
      final shouldSendNow =
          targetDate.isBefore(today) || targetDate.isAtSameMomentAs(today);

      await _firestore.collection('scheduled_emails').add({
        'capsuleId': capsuleId,
        'to': recipientEmail,
        'recipientName': recipientName,
        'senderName': senderName,
        'capsuleTitle': capsuleTitle,
        'sendDate': Timestamp.fromDate(shouldSendNow ? now : sendDate),
        'status': shouldSendNow ? 'immediate' : 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la planification de l\'email: $e');
    }
  }

  /// Génère le contenu HTML du mail avec le style de l'application
  static String generateEmailHtml({
    required String recipientName,
    required String senderName,
    required String capsuleTitle,
    required String openDate,
    required String capsuleUrl,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Capsule Temporelle</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #0A0E1A 0%, #1a1f3a 100%);">
  <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #0A0E1A 0%, #1a1f3a 100%); padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background: rgba(255, 255, 255, 0.08); backdrop-filter: blur(12px); border-radius: 28px; border: 1px solid rgba(255, 255, 255, 0.12); overflow: hidden;">
          
          <!-- Header with stars -->
          <tr>
            <td style="padding: 40px 40px 20px; text-align: center; position: relative;">
              <div style="font-size: 48px; margin-bottom: 10px;">⏳</div>
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: bold;">
                Capsule Temporelle
              </h1>
              <p style="color: rgba(255, 255, 255, 0.7); margin: 10px 0 0; font-size: 16px;">
                Le temps s'écoule, tes souvenirs restent
              </p>
            </td>
          </tr>

          <!-- Greeting -->
          <tr>
            <td style="padding: 30px 40px;">
              <p style="color: #ffffff; font-size: 18px; margin: 0 0 20px;">
                Bonjour <strong>$recipientName</strong> 👋
              </p>
              <p style="color: rgba(255, 255, 255, 0.85); font-size: 16px; line-height: 1.6; margin: 0 0 20px;">
                <strong>$senderName</strong> a créé une capsule temporelle spécialement pour toi !
              </p>
            </td>
          </tr>

          <!-- Capsule Card -->
          <tr>
            <td style="padding: 0 40px 30px;">
              <div style="background: rgba(255, 255, 255, 0.05); border-radius: 16px; padding: 24px; border: 1px solid rgba(255, 255, 255, 0.1);">
                <div style="display: flex; align-items: center; margin-bottom: 16px;">
                  <span style="font-size: 32px; margin-right: 12px;">🔓</span>
                  <div>
                    <h2 style="color: #ffffff; margin: 0; font-size: 20px; font-weight: bold;">
                      $capsuleTitle
                    </h2>
                    <p style="color: rgba(255, 255, 255, 0.6); margin: 4px 0 0; font-size: 14px;">
                      📅 Ouverture : $openDate
                    </p>
                  </div>
                </div>
                <p style="color: rgba(255, 255, 255, 0.7); margin: 16px 0 0; font-size: 14px; line-height: 1.5;">
                  Cette capsule contient des souvenirs, des photos et un message personnel que $senderName a préparé pour toi. Elle est maintenant prête à être découverte ! ✨
                </p>
              </div>
            </td>
          </tr>

          <!-- CTA Button -->
          <tr>
            <td style="padding: 0 40px 40px; text-align: center;">
              <a href="$capsuleUrl" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; padding: 16px 40px; border-radius: 12px; font-size: 16px; font-weight: bold; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);">
                🚀 Ouvrir ma capsule
              </a>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 30px 40px; border-top: 1px solid rgba(255, 255, 255, 0.1); text-align: center;">
              <p style="color: rgba(255, 255, 255, 0.5); margin: 0; font-size: 13px; line-height: 1.6;">
                Cette capsule a été créée avec 💜 sur TimeCapsule<br>
                Un moyen unique de préserver et partager tes souvenirs à travers le temps
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }
}
