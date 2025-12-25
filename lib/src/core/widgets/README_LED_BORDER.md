# AnimatedLedBorder Widget

## Description

Widget Flutter qui ajoute une **bordure LED animée** avec changement de couleur qui tourne autour de n'importe quel élément enfant.

## Effet visuel

- 🌈 **Changement de couleur progressif** entre 5 couleurs par défaut
- 🔄 **Rotation continue** du gradient de couleur
- ✨ **Effet glow/lueur** autour de la bordure
- ⚡ **Animation fluide et performante**

## Utilisation

```dart
import '/src/core/widgets/animated_led_border.dart';

AnimatedLedBorder(
  borderRadius: 28,
  borderWidth: 3,
  animationDuration: const Duration(seconds: 4),
  child: YourWidget(),
)
```

## Paramètres

| Paramètre | Type | Par défaut | Description |
|-----------|------|------------|-------------|
| `child` | Widget | **requis** | Widget enfant à entourer |
| `borderWidth` | double | 2.0 | Épaisseur de la bordure LED |
| `borderRadius` | double | 16.0 | Rayon des coins arrondis |
| `animationDuration` | Duration | 3s | Durée d'un cycle complet |
| `colors` | List<Color> | 5 couleurs | Palette de couleurs |

## Couleurs par défaut

1. 🔵 Bleu (#42A5F5)
2. 🟣 Violet (#AB47BC)
3. 🟢 Vert (#69F0AE)
4. 🌸 Rose (#FF6B9D)
5. 🟠 Orange (#FFA726)

## Personnalisation

### Changer les couleurs

```dart
AnimatedLedBorder(
  colors: const [
    Colors.red,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
  ],
  child: MyWidget(),
)
```

### Vitesse d'animation

```dart
// Animation rapide (1 seconde)
AnimatedLedBorder(
  animationDuration: const Duration(seconds: 1),
  child: MyWidget(),
)

// Animation lente (10 secondes)
AnimatedLedBorder(
  animationDuration: const Duration(seconds: 10),
  child: MyWidget(),
)
```

### Bordure épaisse

```dart
AnimatedLedBorder(
  borderWidth: 5,
  child: MyWidget(),
)
```

## Où c'est utilisé

### Dashboard (liste des capsules)
- Conteneur principal : bordure LED 3px, 4 secondes
- Chaque carte de capsule : bordure LED 2px, 3 secondes

### Page de profil
- Conteneur du formulaire : bordure LED 3px, 4 secondes

### Page de création de capsule
- Conteneur du formulaire : bordure LED 3px, 4 secondes

## Performance

✅ **Optimisé avec CustomPainter** pour des performances maximales
✅ **Utilise SingleTickerProviderStateMixin** pour gérer l'animation
✅ **shouldRepaint intelligent** pour minimiser les repaints

## Notes techniques

- Utilise `SweepGradient` avec rotation pour l'effet tournant
- Applique un `MaskFilter.blur` pour l'effet glow
- Interpolation de couleurs avec `Color.lerp` pour des transitions fluides
- Compatible avec tous les widgets Flutter
