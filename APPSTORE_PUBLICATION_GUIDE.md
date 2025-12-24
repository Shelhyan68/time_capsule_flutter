# Guide de Publication sur l'App Store - Time Capsule

## Configuration actuelle
- **Nom de l'app**: Time Capsule
- **Bundle ID**: com.simacreationweb.timecapsule
- **Version**: 1.0.0+57
- **Team ID**: 9X826KTSA9

## Étapes de publication sur l'App Store

### 1. Prérequis
- [x] Compte développeur Apple actif
- [x] Xcode installé (version 26.1.1)
- [x] CocoaPods installé
- [x] Certificats et profils de provisioning configurés

### 2. Préparation dans Xcode

Le projet Xcode est maintenant ouvert (`Runner.xcworkspace`). Suivez ces étapes dans Xcode:

#### a. Configurer la signature
1. Dans Xcode, sélectionnez le projet **Runner** dans le navigateur
2. Sélectionnez la cible **Runner**
3. Onglet **Signing & Capabilities**:
   - Cochez **Automatically manage signing**
   - Sélectionnez votre **Team** (9X826KTSA9)
   - Vérifiez que le Bundle Identifier est: `com.simacreationweb.timecapsule`

#### b. Vérifier les capabilities
Les capabilities suivantes sont déjà configurées:
- Sign in with Apple
- Push Notifications (Firebase)
- Associated Domains (pour les deep links)

#### c. Configurer la version
- **General > Identity**:
  - Version: 1.0.0
  - Build: 57

### 3. Créer l'archive

1. Dans Xcode, sélectionnez **Product > Destination > Any iOS Device (arm64)**
2. Sélectionnez **Product > Archive**
3. Attendez la fin de la compilation (cela peut prendre plusieurs minutes)

### 4. Uploader vers App Store Connect

1. Une fois l'archive créée, la fenêtre **Organizer** s'ouvrira automatiquement
2. Sélectionnez votre archive dans la liste
3. Cliquez sur **Distribute App**
4. Sélectionnez **App Store Connect**
5. Cliquez sur **Upload**
6. Acceptez les options par défaut et cliquez sur **Next**
7. Vérifiez que tout est correct et cliquez sur **Upload**

### 5. Configuration sur App Store Connect

1. Connectez-vous à [App Store Connect](https://appstoreconnect.apple.com)
2. Cliquez sur **My Apps**
3. Si c'est la première fois, créez une nouvelle app:
   - Cliquez sur le bouton **+** et sélectionnez **New App**
   - Plateforme: iOS
   - Nom: Time Capsule
   - Langue principale: Français
   - Bundle ID: com.simacreationweb.timecapsule
   - SKU: timecapsule (ou un identifiant unique)

#### Informations requises pour la soumission:

##### a. Informations générales
- **Nom de l'app**: Time Capsule
- **Sous-titre**: (max 30 caractères) "Créez des capsules temporelles"
- **Description**: (Décrivez votre application en détail)
- **Mots-clés**: capsule, temporelle, souvenirs, photos, videos, partage
- **URL de support**: Votre site web ou email de support
- **URL marketing**: (optionnel)

##### b. Captures d'écran
Vous devez fournir des captures d'écran pour:
- iPhone 6.9" Display (obligatoire pour iPhone 16 Pro Max)
- iPhone 6.7" Display (iPhone 15 Pro Max, 14 Pro Max)
- iPhone 6.5" Display (iPhone 11 Pro Max, XS Max)

**Dimensions requises**:
- 6.9": 1320 x 2868 pixels ou 2868 x 1320 pixels
- 6.7": 1290 x 2796 pixels ou 2796 x 1290 pixels
- 6.5": 1242 x 2688 pixels ou 2688 x 1242 pixels

**Nombre de captures**: 3 à 10 par taille

##### c. Icône de l'application
- Taille: 1024 x 1024 pixels (déjà générée dans `assets/icon.png`)
- Format: PNG sans transparence
- **Note**: L'avertissement indique que votre icône a un canal alpha (transparence).
  Vous devez supprimer la transparence de votre icône.

##### d. Classification du contenu
- Catégorie principale: Photo et vidéo (ou Social Networking)
- Catégorie secondaire: (optionnel)
- Âge minimum: Déterminez selon le contenu

##### e. Coordonnées
- Prénom et nom
- Numéro de téléphone
- Email

##### f. Notes pour la review
Fournissez des instructions claires pour les testeurs Apple:
- Compte de test (si nécessaire)
- Instructions spéciales pour tester l'app
- Informations sur Firebase/services externes utilisés

### 6. Corriger l'icône (IMPORTANT)

Votre icône actuelle contient de la transparence, ce qui n'est pas autorisé par Apple.

Pour corriger cela:

1. Ouvrez `assets/icon.png` dans un éditeur d'images
2. Supprimez le canal alpha (transparence)
3. Remplacez le fond transparent par une couleur unie (par exemple, le fond bleu foncé #0B0F1A que vous utilisez déjà)
4. Sauvegardez l'image
5. Régénérez les icônes avec:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

Ou ajoutez cette ligne dans `pubspec.yaml` sous `flutter_launcher_icons`:
```yaml
remove_alpha_ios: true
```
Puis exécutez:
```bash
flutter pub run flutter_launcher_icons
```

### 7. Informations de confidentialité

Apple exigera des informations sur:
- Collecte de données utilisateur
- Utilisation de données
- Permissions (caméra, photos, etc.)

Préparez ces informations en fonction de votre application:
- Collecte d'emails (authentification)
- Photos/vidéos (stockage dans Firebase)
- Notifications push

### 8. Soumission pour review

1. Une fois toutes les informations remplies dans App Store Connect
2. Sélectionnez le build uploadé depuis Xcode
3. Cliquez sur **Submit for Review**
4. Répondez aux questions supplémentaires
5. Cliquez sur **Submit**

### 9. Temps de review

- Délai typique: 24-48 heures
- Peut être plus long pour une première soumission
- Vous recevrez un email à chaque changement de statut

### 10. Après l'approbation

Une fois approuvée, vous pouvez:
- Publier immédiatement
- Programmer une date de publication
- Attendre et publier manuellement

## Commandes utiles

### Créer un nouveau build
```bash
# Dans le terminal, depuis la racine du projet
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
flutter clean
flutter pub get
cd ios && /opt/homebrew/bin/pod install && cd ..
```

### Incrémenter la version
Éditez `pubspec.yaml`:
```yaml
version: 1.0.1+58  # 1.0.1 = version, 58 = build number
```

### Vérifier les certificats
```bash
# Dans Xcode, vérifiez:
# Preferences > Accounts > [Votre compte] > Manage Certificates
```

## Résolution de problèmes

### Problème: "No signing certificate"
- Solution: Dans Xcode, Preferences > Accounts, téléchargez les certificats

### Problème: "CocoaPods not working"
- Solution: Exécutez ces commandes:
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
unset GEM_PATH
unset GEM_HOME
cd ios && /opt/homebrew/bin/pod install
```

### Problème: Build échoue
1. Nettoyez le projet: `flutter clean`
2. Supprimez les pods: `rm -rf ios/Pods ios/Podfile.lock`
3. Réinstallez: `cd ios && /opt/homebrew/bin/pod install`
4. Reconstruisez dans Xcode

## Checklist finale avant soumission

- [ ] Icône sans transparence
- [ ] Captures d'écran de toutes les tailles requises
- [ ] Description et mots-clés remplis
- [ ] URL de support valide
- [ ] Informations de confidentialité complètes
- [ ] Build uploadé et sélectionné
- [ ] Classification du contenu appropriée
- [ ] Compte de test fourni (si applicable)
- [ ] Notes pour la review claires

## Contacts et ressources

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer](https://developer.apple.com)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

Bonne chance pour votre soumission!
