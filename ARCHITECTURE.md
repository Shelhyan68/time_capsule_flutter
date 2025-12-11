# Time Capsule - Architecture du Projet

## 📁 Structure du Projet

```
lib/
├── main.dart                           # Point d'entrée de l'application
├── firebase_options.dart               # Configuration Firebase
│
├── src/
│   ├── app_router.dart                # Gestion de la navigation
│   │
│   ├── core/                          # Fonctionnalités partagées
│   │   └── constants/
│   │       └── app_constants.dart     # Couleurs, tailles, styles
│   │
│   └── features/                      # Fonctionnalités par domaine
│       │
│       ├── auth/                      # Authentification
│       │   ├── data/
│       │   │   ├── auth_repository.dart
│       │   │   └── google_auth_service.dart
│       │   └── presentation/
│       │       ├── pages/
│       │       │   ├── login_page.dart
│       │       │   ├── register_page.dart
│       │       │   └── reset_password_page.dart
│       │       └── widgets/
│       │           └── auth_text_field.dart
│       │
│       └── capsule/                   # Gestion des capsules temporelles
│           ├── data/
│           │   └── capsule_service.dart
│           ├── domain/
│           │   └── models/
│           │       └── capsule_model.dart
│           └── presentation/
│               ├── pages/
│               │   ├── dashboard_page.dart
│               │   ├── create_capsule_page.dart
│               │   └── open_capsule_page.dart
│               └── widgets/
│                   ├── animated_lock_icon.dart
│                   ├── capsule_card.dart
│                   ├── countdown_timer.dart
│                   ├── empty_capsule_state.dart
│                   ├── exploding_particles.dart
│                   └── opened_capsule_content.dart
```

## 🏗️ Architecture

Ce projet suit une **architecture Clean** modifiée adaptée à Flutter :

### 1. **Domain Layer (Domaine)**
- **Localisation** : `features/{feature}/domain/`
- **Responsabilité** : Contient les modèles de données et la logique métier pure
- **Exemple** : `CapsuleModel` représente une capsule temporelle

### 2. **Data Layer (Données)**
- **Localisation** : `features/{feature}/data/`
- **Responsabilité** : Gestion des sources de données (Firebase, API, cache)
- **Exemple** : `CapsuleService` pour les opérations CRUD sur Firestore

### 3. **Presentation Layer (Présentation)**
- **Localisation** : `features/{feature}/presentation/`
- **Responsabilité** : Interface utilisateur et logique d'affichage
- **Sous-dossiers** :
  - `pages/` : Écrans complets de l'application
  - `widgets/` : Composants réutilisables

### 4. **Core (Noyau)**
- **Localisation** : `src/core/`
- **Responsabilité** : Utilitaires et constantes partagées
- **Contenu** : Thèmes, couleurs, styles, helpers

## 🎨 Conventions de Code

### Naming
- **Classes** : PascalCase (`CapsuleModel`, `DashboardPage`)
- **Fichiers** : snake_case (`capsule_model.dart`, `dashboard_page.dart`)
- **Variables/Fonctions** : camelCase (`getCapsules`, `isUnlocked`)
- **Constantes** : camelCase avec `static const` (`AppColors.background`)

### Organisation des Imports
```dart
// 1. Imports Dart
import 'dart:async';
import 'dart:ui';

// 2. Packages Flutter
import 'package:flutter/material.dart';

// 3. Packages tiers
import 'package:cloud_firestore/cloud_firestore.dart';

// 4. Imports locaux (absolus)
import '/src/core/constants/app_constants.dart';
import '/src/features/capsule/domain/models/capsule_model.dart';

// 5. Imports locaux (relatifs pour la même feature)
import '../widgets/countdown_timer.dart';
```

### Structure d'un Widget
```dart
class MyWidget extends StatelessWidget {
  // 1. Propriétés finales
  final String title;
  final VoidCallback onTap;
  
  // 2. Constructeur
  const MyWidget({
    super.key,
    required this.title,
    required this.onTap,
  });
  
  // 3. Méthodes privées (si nécessaire)
  void _handleAction() { }
  
  // 4. Build method
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## 🔥 Firebase

### Collections Firestore
- **capsules** : Stocke les capsules temporelles
  ```
  {
    id: String (auto-généré),
    title: String,
    letter: String?,
    mediaUrls: List<String>,
    openDate: Timestamp
  }
  ```

### Firebase Storage
- **capsules/{timestamp}_{filename}** : Stockage des médias

## 🚀 Bonnes Pratiques

### Widgets
- ✅ Extraire les widgets complexes dans des fichiers séparés
- ✅ Utiliser `const` autant que possible pour optimiser les performances
- ✅ Préférer `StatelessWidget` quand l'état n'est pas nécessaire
- ✅ Donner des noms descriptifs aux widgets (`AnimatedLockIcon` plutôt que `Icon1`)

### Gestion d'État
- ✅ Utiliser `StreamBuilder` pour les données en temps réel
- ✅ Utiliser `setState` pour l'état local simple
- ✅ Gérer les états de chargement et d'erreur

### Services
- ✅ Centraliser les appels Firebase dans des services dédiés
- ✅ Ajouter des try-catch et des messages d'erreur explicites
- ✅ Documenter les méthodes publiques

### Style
- ✅ Utiliser les constantes de `AppConstants` pour les couleurs et tailles
- ✅ Respecter le design glassmorphism de l'application
- ✅ Maintenir une cohérence visuelle

## 📦 Dépendances Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.15.2
  firebase_auth: ^5.7.0
  cloud_firestore: ^5.6.12
  firebase_storage: ^12.4.10
  image_picker: ^1.0.0
  file_picker: ^8.3.7
```

## 🔄 Flux de Données

1. **Lecture** : `Firestore` → `CapsuleService.getCapsules()` → `StreamBuilder` → `UI`
2. **Création** : `UI` → `CapsuleService.createCapsule()` → `Firestore`
3. **Suppression** : `UI` → `CapsuleService.deleteCapsule()` → `Firestore` + `Storage`

## 📝 TODO

- [ ] Ajouter des tests unitaires pour les services
- [ ] Implémenter la gestion d'état avec Provider/Riverpod
- [ ] Ajouter la pagination pour les listes de capsules
- [ ] Implémenter le lecteur vidéo
- [ ] Ajouter l'internationalisation (i18n)

---

**Dernière mise à jour** : 11 décembre 2025
