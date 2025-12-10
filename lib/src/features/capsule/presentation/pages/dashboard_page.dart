import 'package:flutter/material.dart';
import '/src/features/auth/data/auth_repository.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              try {
                authRepository.logout();
                // Pas besoin de Navigator : StreamBuilder dans main.dart gère le retour
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
          ),
        ],
      ),
      body: const Center(child: Text('Bienvenue dans TimeCapsule !')),
    );
  }
}
