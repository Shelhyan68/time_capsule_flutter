import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import 'register_page.dart';
import 'reset_password_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();

    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authRepository.login(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Se connecter'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
              },
              child: const Text('Créer un compte'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                );
              },
              child: const Text('Mot de passe oublié ?'),
            ),
            const Divider(),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Se connecter avec Google'),
              onPressed: () async {
                try {
                  await authRepository.signInWithGoogle();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            ),
            const SizedBox(height: 8),
            if (Theme.of(context).platform == TargetPlatform.iOS)
              ElevatedButton.icon(
                icon: const Icon(Icons.apple),
                label: const Text('Se connecter avec Apple'),
                onPressed: () async {
                  try {
                    await authRepository.signInWithApple();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
