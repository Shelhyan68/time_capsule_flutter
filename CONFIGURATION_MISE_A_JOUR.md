# Configuration du système de mise à jour

## Vue d'ensemble

L'application vérifie automatiquement au démarrage si une mise à jour est disponible en consultant Firestore.

## Configuration Firestore

Créez un document dans Firestore avec le chemin suivant :
```
Collection: app_config
Document ID: version
```

### Structure du document

```json
{
  "latestVersion": "1.0.0",
  "latestBuildNumber": 65,
  "minBuildNumber": 60,
  "updateMessage": "Nouvelle version avec vérification automatique des mises à jour !",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.simacreation.timecapsule"
}
```

### Champs

- **latestVersion** (string) : La dernière version disponible (ex: "1.0.0")
- **latestBuildNumber** (number) : Le numéro de build de la dernière version (ex: 65)
- **minBuildNumber** (number) : Le numéro de build minimum requis (ex: 60)
  - Si l'utilisateur a un buildNumber < minBuildNumber → **Mise à jour OBLIGATOIRE**
  - Si l'utilisateur a un buildNumber < latestBuildNumber → **Mise à jour OPTIONNELLE**
- **updateMessage** (string, optionnel) : Message personnalisé à afficher dans la dialog
- **updateUrl** (string, optionnel) : URL vers le Play Store ou App Store
  - Si non fournie, l'app détectera automatiquement la plateforme :
    - **Android** : `https://play.google.com/store/apps/details?id=com.simacreation.timecapsule`
    - **iOS** : `https://apps.apple.com/app/idVOTRE_APP_ID` (remplacez VOTRE_APP_ID par l'ID de votre app sur l'App Store)

## Comportement

### Mise à jour optionnelle
- L'utilisateur peut fermer la dialog et continuer à utiliser l'app
- Message informatif avec icône bleue
- Bouton "Plus tard" disponible

### Mise à jour obligatoire
- La dialog ne peut pas être fermée
- Message d'avertissement avec icône orange
- Seul le bouton "Mettre à jour" est disponible
- L'utilisateur ne peut pas utiliser l'app tant qu'il n'a pas mis à jour

## Création du document Firestore

### Via la Console Firebase (Méthode recommandée)

1. **Accéder à Firestore**
   - Allez sur https://console.firebase.google.com
   - Sélectionnez votre projet **time-capsule-5ecb5**
   - Cliquez sur **Firestore Database** dans le menu

2. **Créer la collection `app_config`**
   - Cliquez sur "Commencer une collection"
   - ID de collection : `app_config`
   - Cliquez sur "Suivant"

3. **Créer le document `version`**
   - ID du document : `version`
   - Ajoutez les 5 champs :

   | Champ | Type | Valeur |
   |-------|------|--------|
   | latestVersion | string | 1.0.0 |
   | latestBuildNumber | number | 65 |
   | minBuildNumber | number | 60 |
   | updateMessage | string | Nouvelle version avec correction de la suppression de compte ! |
   | updateUrl | string | https://play.google.com/store/apps/details?id=com.simacreation.timecapsule |

4. **Enregistrer**
   - Cliquez sur "Enregistrer"

## Processus de release

1. Mettre à jour `pubspec.yaml` avec le nouveau buildNumber
2. Builder et publier l'app sur le Play Store / App Store
3. Une fois l'app publiée, mettre à jour le document Firestore :
   - `latestBuildNumber` → nouveau numéro de build
   - `latestVersion` → nouvelle version si changée
   - `updateMessage` → message de cette release
   - `minBuildNumber` → ajuster si besoin (pour forcer la mise à jour)
   - `updateUrl` → optionnel, pour personnaliser l'URL

## Exemples

### Mise à jour optionnelle (Android + iOS)
```json
{
  "latestVersion": "1.0.0",
  "latestBuildNumber": 65,
  "minBuildNumber": 60,
  "updateMessage": "Une nouvelle version est disponible avec de nouvelles fonctionnalités !"
}
```
→ L'URL sera automatiquement détectée selon la plateforme

### Mise à jour obligatoire avec URL personnalisée
```json
{
  "latestVersion": "1.0.0",
  "latestBuildNumber": 70,
  "minBuildNumber": 70,
  "updateMessage": "Cette mise à jour corrige un problème de sécurité important.",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.simacreation.timecapsule"
}
```
→ Tous les utilisateurs devront obligatoirement mettre à jour
