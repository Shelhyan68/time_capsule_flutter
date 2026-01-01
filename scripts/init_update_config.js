// Script pour initialiser la configuration de mise à jour dans Firestore
// Exécuter avec : node scripts/init_update_config.js

const admin = require('firebase-admin');

// Initialiser Firebase Admin
const serviceAccount = require('../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function initUpdateConfig() {
  try {
    const updateConfig = {
      latestVersion: '1.0.0',
      latestBuildNumber: 63,
      minBuildNumber: 60,
      updateMessage: 'Une nouvelle version est disponible !',
      updateUrl: 'https://play.google.com/store/apps/details?id=com.simacreation.timecapsule'
    };

    await db.collection('app_config').doc('version').set(updateConfig);

    console.log('✅ Configuration de mise à jour initialisée avec succès !');
    console.log('Configuration:', updateConfig);

    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors de l\'initialisation:', error);
    process.exit(1);
  }
}

initUpdateConfig();
