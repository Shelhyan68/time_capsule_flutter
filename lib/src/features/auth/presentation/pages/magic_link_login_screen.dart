import 'package:flutter/material.dart';
import 'package:time_capsule/src/features/auth/data/magic_link_service.dart';

class MagicLinkLoginScreen extends StatefulWidget {
  const MagicLinkLoginScreen({super.key});

  @override
  State<MagicLinkLoginScreen> createState() => _MagicLinkLoginScreenState();
}

class _MagicLinkLoginScreenState extends State<MagicLinkLoginScreen> {
  final _emailController = TextEditingController();
  final _magicLinkService = MagicLinkService();
  bool _isLoading = false;
  bool _linkSent = false;

  Future<void> _sendMagicLink() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _magicLinkService.sendMagicLink(_emailController.text.trim());

      setState(() {
        _linkSent = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✉️ Magic link envoyé ! Vérifiez vos emails.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo ou icône
            const Icon(
              Icons.email_outlined,
              size: 80,
              color: Color(0xFF667eea),
            ),
            const SizedBox(height: 32),

            // Titre
            const Text(
              'Connexion sans mot de passe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            const Text(
              'Recevez un lien magique par email pour vous connecter instantanément',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            if (!_linkSent) ...[
              // Champ email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'votre@email.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bouton d'envoi
              ElevatedButton(
                onPressed: _isLoading ? null : _sendMagicLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '🪄 Envoyer le magic link',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ] else ...[
              // Message de confirmation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Email envoyé !',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consultez votre boîte email ${_emailController.text} et cliquez sur le lien pour vous connecter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() => _linkSent = false);
                      },
                      child: const Text('Utiliser un autre email'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
