import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import '/src/core/widgets/animated_led_border.dart';
import '/src/core/widgets/space_background.dart';

/// Page de connexion avec 3 méthodes : Magic Link, Google, Apple (iOS).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authRepository = AuthRepository();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _magicLinkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authRepository.sendMagicLink(_emailController.text.trim());

      if (mounted) {
        setState(() => _magicLinkSent = true);
        _showMessage(
          '✉️ Lien magique envoyé ! Vérifiez votre email.',
          isError: false,
        );
      }
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Erreur lors de l\'envoi du lien');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _authRepository.signInWithGoogle();
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Erreur de connexion Google');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      await _authRepository.signInWithApple();
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Erreur de connexion Apple');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    // Padding adaptatif selon la taille de l'écran
    final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;
    final verticalPadding = isSmallScreen ? 12.0 : 24.0;

    return SpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (verticalPadding * 2),
                  ),
                  child: Center(
                    child: _buildCard(
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
                      screenWidth: screenWidth,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required bool isSmallScreen,
    required bool isVerySmallScreen,
    required double screenWidth,
  }) {
    final cardPadding = isSmallScreen ? 20.0 : 28.0;

    return AnimatedLedBorder(
      borderRadius: 28,
      borderWidth: 2,
      glowIntensity: 10,
      animationDuration: const Duration(seconds: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: screenWidth < 500 ? double.infinity : 400,
            ),
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(
                isSmallScreen: isSmallScreen,
                isVerySmallScreen: isVerySmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 20 : 32),
              if (_magicLinkSent)
                _buildMagicLinkSentMessage(isSmallScreen: isSmallScreen)
              else
                _buildLoginForm(isSmallScreen: isSmallScreen),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isSmallScreen,
    required bool isVerySmallScreen,
  }) {
    final logoSize = isVerySmallScreen ? 56.0 : (isSmallScreen ? 64.0 : 80.0);
    final iconSize = isVerySmallScreen ? 28.0 : (isSmallScreen ? 32.0 : 40.0);
    final titleSize = isVerySmallScreen ? 20.0 : (isSmallScreen ? 22.0 : 26.0);
    final subtitleSize = isVerySmallScreen ? 12.0 : 14.0;

    return Column(
      children: [
        // Logo
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
          ),
          child: Icon(
            Icons.hourglass_empty,
            size: iconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 20),
        Text(
          'Capsule Temporelle',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Text(
          'Préservez vos souvenirs dans le temps',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: subtitleSize,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMagicLinkSentMessage({required bool isSmallScreen}) {
    final iconSize = isSmallScreen ? 40.0 : 48.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.mark_email_read, size: iconSize, color: Colors.green),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'Vérifiez votre email !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                'Un lien magique a été envoyé à\n${_emailController.text}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        TextButton(
          onPressed: () => setState(() => _magicLinkSent = false),
          child: const Text('← Utiliser un autre email'),
        ),
      ],
    );
  }

  Widget _buildLoginForm({required bool isSmallScreen}) {
    final buttonHeight = isSmallScreen ? 48.0 : 52.0;
    final spacing = isSmallScreen ? 16.0 : 20.0;
    final dividerSpacing = isSmallScreen ? 20.0 : 28.0;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email input
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Email invalide';
              }
              return null;
            },
            decoration: _inputDecoration(
              label: 'Email',
              icon: Icons.email_outlined,
              isSmallScreen: isSmallScreen,
            ),
          ),
          SizedBox(height: spacing),

          // Magic Link button
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _sendMagicLink,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(
                _isLoading ? 'Envoi...' : 'Recevoir un lien magique',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          SizedBox(height: dividerSpacing),
          _buildDivider(isSmallScreen: isSmallScreen),
          SizedBox(height: dividerSpacing),

          // Social buttons
          _buildSocialButtons(isSmallScreen: isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildDivider({required bool isSmallScreen}) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          child: Text(
            'ou continuer avec',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: isSmallScreen ? 11 : 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
      ],
    );
  }

  Widget _buildSocialButtons({required bool isSmallScreen}) {
    final isIOS = Platform.isIOS || Platform.isMacOS;
    final buttonHeight = isSmallScreen ? 46.0 : 50.0;

    return Column(
      children: [
        // Google
        _buildSocialButton(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: Image.network(
            'https://www.google.com/favicon.ico',
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.g_mobiledata, color: Colors.white),
          ),
          label: 'Google',
          height: buttonHeight,
          isSmallScreen: isSmallScreen,
        ),

        // Apple (iOS/macOS only)
        if (isIOS) ...[
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildSocialButton(
            onPressed: _isLoading ? null : _signInWithApple,
            icon: const Icon(Icons.apple, color: Colors.white, size: 22),
            label: 'Apple',
            height: buttonHeight,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
    required double height,
    required bool isSmallScreen,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label, style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: isSmallScreen ? 14 : 16,
      ),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 14 : 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.blue.shade400),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}
