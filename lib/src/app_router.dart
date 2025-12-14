import 'package:flutter/material.dart';
import 'features/capsule/presentation/pages/dashboard_page.dart';
import 'features/capsule/presentation/pages/create_capsule_page.dart';
import 'features/capsule/presentation/pages/open_capsule_page.dart';
import 'features/capsule/domain/models/capsule_model.dart';
import 'features/user/presentation/pages/profile_setup_page.dart';
import 'features/user/presentation/pages/profile_page.dart';

/// Widget qui ferme la route actuelle et retourne à la home (logique auth)
class _PopToHome extends StatefulWidget {
  const _PopToHome();

  @override
  State<_PopToHome> createState() => _PopToHomeState();
}

class _PopToHomeState extends State<_PopToHome> {
  @override
  void initState() {
    super.initState();
    // Fermer cette route après le build pour retourner à home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B0F1A),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case '/create':
        return MaterialPageRoute(builder: (_) => const CreateCapsulePage());
      case '/profile-setup':
        return MaterialPageRoute(builder: (_) => const ProfileSetupPage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case '/open':
        final capsule = settings.arguments as CapsuleModel?;
        if (capsule == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('Erreur: capsule non fournie')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => OpenCapsulePage(capsule: capsule),
        );
      // Routes pour les deep links Firebase Auth - retourner à la home (logique auth)
      case '/action':
      case '/__/auth/action':
        return MaterialPageRoute(builder: (_) => const _PopToHome());
      default:
        // Toute route inconnue -> retourner à home
        return MaterialPageRoute(builder: (_) => const _PopToHome());
    }
  }
}
