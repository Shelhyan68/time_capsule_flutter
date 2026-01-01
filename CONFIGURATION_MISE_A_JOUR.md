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
  "latestBuildNumber": 63,
  "minBuildNumber": 60,
  "updateMessage": "Nouvelle version avec amélioration de la suppression de compte !",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.simacreation.timecapsule"
}
```

### Champs

- **latestVersion** (string) : La dernière version disponible (ex: "1.0.0")
- **latestBuildNumber** (number) : Le numéro de build de la dernière version (ex: 63)
- **minBuildNumber** (number) : Le numéro de build minimum requis (ex: 60)
  - Si l'utilisateur a un buildNumber < minBuildNumber → **Mise à jour OBLIGATOIRE**
  - Si l'utilisateur a un buildNumber < latestBuildNumber → **Mise à jour OPTIONNELLE**
- **updateMessage** (string, optionnel) : Message personnalisé à afficher dans la dialog
- **updateUrl** (string, optionnel) : URL vers le Play Store ou App Store
  - Par défaut : `https://play.google.com/store/apps/details?id=com.simacreation.timecapsule`

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

## Exemple de configuration

### Scénario 1 : Nouvelle version optionnelle
```json
{
  "latestVersion": "1.0.0",
  "latestBuildNumber": 65,
  "minBuildNumber": 60,
  "updateMessage": "Une nouvelle version est disponible avec de nouvelles fonctionnalités !",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.simacreation.timecapsule"
}
```
→ Les utilisateurs avec buildNumber 60-64 verront une mise à jour optionnelle

### Scénario 2 : Mise à jour obligatoire
```json
{
  "latestVersion": "1.0.0",
  "latestBuildNumber": 65,
  "minBuildNumber": 65,
  "updateMessage": "Cette mise à jour corrige un problème de sécurité important.",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.simacreation.timecapsule"
}
```
→ Tous les utilisateurs avec buildNumber < 65 devront obligatoirement mettre à jour

## Console Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet `time-capsule-5ecb5`
3. Allez dans **Firestore Database**
4. Créez la collection `app_config` si elle n'existe pas
5. Créez le document `version` avec les champs ci-dessus
6. Mettez à jour ces valeurs à chaque nouvelle release

## Processus de release

1. Mettre à jour `pubspec.yaml` avec le nouveau buildNumber
2. Builder et publier l'app sur le Play Store
3. Une fois l'app publiée, mettre à jour le document Firestore :
   - `latestBuildNumber` → nouveau numéro de build
   - `latestVersion` → nouvelle version si changée
   - `updateMessage` → message de cette release
   - `minBuildNumber` → ajuster si besoin (pour forcer la mise à jour)
