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
    required String letter,
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
        'letter': letter,
      });
    } catch (e) {
      throw Exception('Erreur lors de la planification de l\'email: $e');
    }
  }

  /// Génère le contenu HTML du mail avec le style de l'application
  /// Optimisé pour SendGrid et Gmail iOS dark mode
  static String generateEmailHtml({
    required String recipientName,
    required String senderName,
    required String capsuleTitle,
    required String openDate,
    required String capsuleUrl,
    required String letter,
  }) {
    return '''
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <meta name="color-scheme" content="light only" />
  <meta name="supported-color-schemes" content="light" />
  <title>Capsule Temporelle</title>
  <style type="text/css">
    /* SendGrid: Désactiver le dark mode automatique */
    :root {
      color-scheme: light only;
      supported-color-schemes: light;
    }
    
    /* Force le mode clair */
    @media (prefers-color-scheme: dark) {
      :root {
        color-scheme: light !important;
      }
      
      /* Force toutes les couleurs */
      * {
        color-scheme: light !important;
      }
      
      body {
        background-color: #f4f6fb !important;
        color: #1f2937 !important;
      }
      
      .bg-body { background-color: #f4f6fb !important; }
      .bg-white { background-color: #ffffff !important; }
      .bg-gray { background-color: #f9fafb !important; }
      .bg-gradient { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; }
      
      .text-dark { color: #1f2937 !important; }
      .text-gray { color: #374151 !important; }
      .text-muted { color: #6b7280 !important; }
      .text-white { color: #ffffff !important; }
      .text-light { color: #eef0ff !important; }
      
      .border-gray { border-color: #e5e7eb !important; }
    }
    
    /* Empêcher Gmail et SendGrid d'appliquer leurs styles */
    [data-ogsc] * {
      color-scheme: light !important;
    }
    
    [data-ogsc] .bg-body,
    [data-ogsc] body {
      background-color: #f4f6fb !important;
    }
    
    [data-ogsc] .bg-white {
      background-color: #ffffff !important;
    }
    
    [data-ogsc] .text-dark {
      color: #1f2937 !important;
    }
    
    [data-ogsc] .text-gray {
      color: #374151 !important;
    }
    
    /* Support des anciens clients email */
    body {
      margin: 0 !important;
      padding: 0 !important;
      -webkit-text-size-adjust: 100% !important;
      -ms-text-size-adjust: 100% !important;
    }
    
    table {
      border-collapse: collapse !important;
      mso-table-lspace: 0pt !important;
      mso-table-rspace: 0pt !important;
    }
    
    img {
      border: 0 !important;
      outline: none !important;
      -ms-interpolation-mode: bicubic !important;
    }
  </style>
</head>

<body class="bg-body" bgcolor="#f4f6fb" style="margin: 0; padding: 0; background-color: #f4f6fb; font-family: Arial, Helvetica, sans-serif; color-scheme: light;">
  
  <table border="0" cellpadding="0" cellspacing="0" width="100%" class="bg-body" bgcolor="#f4f6fb" style="background-color: #f4f6fb; color-scheme: light;">
    <tr>
      <td align="center" valign="top" style="padding: 32px 16px;">
        
        <!-- Container 600px -->
        <table border="0" cellpadding="0" cellspacing="0" width="600" class="bg-white" bgcolor="#ffffff" style="max-width: 600px; background-color: #ffffff; border-radius: 20px; overflow: hidden;">
          
          <!-- Header avec gradient -->
          <tr>
            <td class="bg-gradient" align="center" bgcolor="#667eea" style="padding: 32px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
              <table border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="center">
                    <div style="font-size: 42px; line-height: 42px; margin-bottom: 12px;">⏳</div>
                    <h1 class="text-white" style="margin: 0; padding: 0; color: #ffffff; font-size: 26px; font-weight: bold; font-family: Arial, Helvetica, sans-serif;">
                      Capsule Temporelle
                    </h1>
                    <p class="text-light" style="margin: 8px 0 0; padding: 0; color: #eef0ff; font-size: 15px; font-family: Arial, Helvetica, sans-serif;">
                      Le temps s'écoule, tes souvenirs restent
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
          <!-- Greeting -->
          <tr>
            <td class="bg-white" bgcolor="#ffffff" style="padding: 32px; background-color: #ffffff;">
              <table border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td>
                    <p class="text-dark" style="margin: 0 0 16px; padding: 0; font-size: 17px; color: #1f2937; font-family: Arial, Helvetica, sans-serif;">
                      Bonjour <strong style="color: #1f2937;">$recipientName</strong>,
                    </p>
                    <p class="text-gray" style="margin: 0; padding: 0; font-size: 16px; line-height: 24px; color: #374151; font-family: Arial, Helvetica, sans-serif;">
                      <strong style="color: #374151;">$senderName</strong> a créé une capsule temporelle pour toi. Elle contient un message et des souvenirs qu'il ou elle a souhaité te transmettre.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
          <!-- Capsule Card -->
          <tr>
            <td class="bg-white" bgcolor="#ffffff" style="padding: 0 32px 32px; background-color: #ffffff;">
              
              <!-- Inner card table -->
              <table border="0" cellpadding="0" cellspacing="0" width="100%" class="bg-gray border-gray" bgcolor="#f9fafb" style="background-color: #f9fafb; border-radius: 16px; border: 1px solid #e5e7eb;">
                <tr>
                  <td style="padding: 24px;">
                    <table border="0" cellpadding="0" cellspacing="0" width="100%">
                      <tr>
                        <td>
                          <!-- Title -->
                          <h2 class="text-dark" style="margin: 0 0 6px; padding: 0; font-size: 20px; color: #111827; font-weight: bold; font-family: Arial, Helvetica, sans-serif;">
                            🕰️ $capsuleTitle
                          </h2>
                          
                          <!-- Date -->
                          <p class="text-muted" style="margin: 0 0 16px; padding: 0; font-size: 14px; color: #6b7280; font-family: Arial, Helvetica, sans-serif;">
                            Ouverture prévue le $openDate
                          </p>
                          
                          <!-- Content box -->
                          <table border="0" cellpadding="0" cellspacing="0" width="100%" class="bg-white border-gray" bgcolor="#ffffff" style="background-color: #ffffff; border-radius: 12px; border: 1px solid #e5e7eb;">
                            <tr>
                              <td style="padding: 20px;">
                                <p class="text-gray" style="margin: 0; padding: 0; font-size: 15px; line-height: 25px; color: #374151; font-family: Arial, Helvetica, sans-serif; white-space: pre-line;">$letter</p>
                              </td>
                            </tr>
                          </table>
                          
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td class="bg-gray" align="center" bgcolor="#f9fafb" style="padding: 24px 32px; background-color: #f9fafb;">
              <table border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="center">
                    <p class="text-muted" style="margin: 0; padding: 0; font-size: 13px; color: #6b7280; line-height: 20px; font-family: Arial, Helvetica, sans-serif;">
                      Capsule créée avec ❤️ sur <strong style="color: #6b7280;">TimeCapsule</strong><br/>
                      Un moyen unique de préserver et partager tes souvenirs
                    </p>
                  </td>
                </tr>
              </table>
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
