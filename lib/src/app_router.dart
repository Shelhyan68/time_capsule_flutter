import 'package:flutter/material.dart';
import 'features/capsule/presentation/pages/dashboard_page.dart';
import 'features/capsule/presentation/pages/create_capsule_page.dart';
import 'features/capsule/presentation/pages/open_capsule_page.dart';
import 'features/capsule/presentation/models/capsule_model.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case '/create':
        return MaterialPageRoute(builder: (_) => const CreateCapsulePage());
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
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
