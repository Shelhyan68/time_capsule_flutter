
# Configuration de l'envoi d'emails automatique

## Vue d'ensemble

L'application TimeCapsule peut envoyer automatiquement des emails aux destinataires lorsqu'une capsule temporelle arrive à sa date d'ouverture. Cela nécessite la configuration de Firebase Cloud Functions et d'un service d'envoi d'emails.

## Architecture

1. **Flutter App** → Crée un document dans `scheduled_emails` avec les détails
2. **Cloud Functions** → Surveille la collection et envoie les emails à la date programmée
3. **SendGrid/Mailgun** → Service SMTP pour l'envoi réel des emails

## Étape 1 : Configuration Firebase Cloud Functions

### Initialiser Firebase Functions

```bash
cd time_capsule
firebase init functions
```

Choisir :
- TypeScript ou JavaScript
- Installer les dépendances

### Structure du projet

```
functions/
├── src/
│   └── index.ts
├── package.json
└── tsconfig.json
```

## Étape 2 : Installer les dépendances

```bash
cd functions
npm install @sendgrid/mail
# OU
npm install nodemailer
```

## Étape 3 : Code de la Cloud Function

Créer `functions/src/index.ts` :

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as sgMail from '@sendgrid/mail';

admin.initializeApp();

// Configurer SendGrid
sgMail.setApiKey(functions.config().sendgrid.key);

// Fonction déclenchée quotidiennement pour vérifier les emails à envoyer
export const sendScheduledEmails = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const db = admin.firestore();

    // Récupérer les emails en attente dont la date est passée
    const snapshot = await db
      .collection('scheduled_emails')
      .where('status', '==', 'pending')
      .where('sendDate', '<=', now)
      .get();

    const promises = snapshot.docs.map(async (doc) => {
      const data = doc.data();

      try {
        // Récupérer les détails de la capsule
        const capsuleDoc = await db
          .collection('capsules')
          .doc(data.capsuleId)
          .get();
        
        const capsule = capsuleDoc.data();
        
        // Formater la date
        const openDate = new Date(data.sendDate.toDate());
        const formattedDate = openDate.toLocaleDateString('fr-FR', {
          day: 'numeric',
          month: 'long',
          year: 'numeric'
        });

        // URL de la capsule (adapter selon votre domaine)
        const capsuleUrl = \`https://your-app.web.app/capsule/\${data.capsuleId}\`;

        // Générer le HTML (utiliser le template de EmailService.generateEmailHtml)
        const htmlContent = generateEmailHtml({
          recipientName: data.recipientName,
          senderName: data.senderName,
          capsuleTitle: data.capsuleTitle,
          openDate: formattedDate,
          capsuleUrl: capsuleUrl,
        });

        // Envoyer l'email
        const msg = {
          to: data.to,
          from: 'noreply@timecapsule.app', // Votre email vérifié
          subject: \`🎁 \${data.senderName} t'a envoyé une capsule temporelle !\`,
          html: htmlContent,
        };

        await sgMail.send(msg);

        // Marquer comme envoyé
        await doc.ref.update({
          status: 'sent',
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(\`Email sent to \${data.to} for capsule \${data.capsuleId}\`);
      } catch (error) {
        console.error(\`Error sending email to \${data.to}:\`, error);
        
        // Marquer comme erreur
        await doc.ref.update({
          status: 'error',
          error: error.message,
          lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

    await Promise.all(promises);
    return null;
  });

// Copier la fonction generateEmailHtml de EmailService ici
function generateEmailHtml(params: {
  recipientName: string;
  senderName: string;
  capsuleTitle: string;
  openDate: string;
  capsuleUrl: string;
}): string {
  // Copier le contenu de EmailService.generateEmailHtml()
  // ...
  return \`<!-- HTML template -->\`;
}
```

## Étape 4 : Configuration SendGrid

1. Créer un compte sur [SendGrid](https://sendgrid.com/)
2. Créer une API Key
3. Vérifier votre domaine d'envoi

```bash
firebase functions:config:set sendgrid.key="VOTRE_API_KEY"
```

## Étape 5 : Déployer

```bash
cd functions
npm run build
firebase deploy --only functions
```

## Alternative : Nodemailer (SMTP)

Si vous préférez utiliser un serveur SMTP :

```typescript
import * as nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.password,
  },
});

await transporter.sendMail({
  from: '"TimeCapsule" <noreply@timecapsule.app>',
  to: data.to,
  subject: \`🎁 \${data.senderName} t'a envoyé une capsule temporelle !\`,
  html: htmlContent,
});
```

## Règles de sécurité Firestore

Ajouter dans `firestore.rules` :

```
match /scheduled_emails/{emailId} {
  // Seules les fonctions cloud peuvent lire/écrire
  allow read, write: if false;
}
```

## Test

Pour tester localement :

```bash
firebase emulators:start
```

## Prix

- **SendGrid** : 100 emails/jour gratuits
- **Cloud Functions** : Première exécution quotidienne gratuite
- **Firestore** : Lectures/écritures incluses dans le plan gratuit pour volumes modérés

## Monitoring

Voir les logs :

```bash
firebase functions:log
```

## Collection Firestore

Structure de `scheduled_emails` :
```json
{
  "capsuleId": "abc123",
  "to": "destinataire@example.com",
  "recipientName": "Marie",
  "senderName": "Jean Dupont",
  "capsuleTitle": "Souvenirs 2024",
  "sendDate": Timestamp(2025-01-01),
  "status": "pending|sent|error",
  "createdAt": Timestamp,
  "sentAt": Timestamp,
  "error": "message d'erreur si applicable"
}
```

## Support

Pour toute question, consulter la documentation Firebase :
- [Cloud Functions](https://firebase.google.com/docs/functions)
- [SendGrid API](https://docs.sendgrid.com/)
