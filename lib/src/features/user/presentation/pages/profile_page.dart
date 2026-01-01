import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '/src/core/constants/app_constants.dart';
import '/src/core/widgets/space_background.dart';
import '/src/core/widgets/animated_led_border.dart';
import '../../data/user_service.dart';
import '../../domain/models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _newProfileImage;
  DateTime? _birthDate;
  bool _isLoading = false;
  bool _isEditing = false;
  UserProfile? _currentProfile;

  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = UserService(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getCurrentUserProfile();
      if (profile != null) {
        setState(() {
          _currentProfile = profile;
          _firstNameController.text = profile.firstName;
          _lastNameController.text = profile.lastName;
          _birthDate = profile.birthDate;
        });
      }
    } catch (e) {
      _showMessage('Erreur lors du chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (picked != null) {
        setState(() => _newProfileImage = File(picked.path));
      }
    } catch (e) {
      _showMessage('Erreur lors de la sélection: $e');
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.capsuleUnlocked,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1F2C),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1A1F2C),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<String?> _uploadProfileImage() async {
    if (_newProfileImage == null) return _currentProfile?.photoUrl;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance.ref().child(
        'profiles/${user.uid}/avatar.jpg',
      );

      await ref.putFile(_newProfileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur upload: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentProfile == null) return;

    setState(() => _isLoading = true);

    try {
      // Upload la nouvelle image si elle existe
      String? photoUrl = _currentProfile!.photoUrl;
      if (_newProfileImage != null) {
        photoUrl = await _uploadProfileImage();
      }

      final updatedProfile = UserProfile(
        uid: _currentProfile!.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        photoUrl: photoUrl,
        email: _currentProfile!.email,
        birthDate: _birthDate,
        createdAt: _currentProfile!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _userService.updateUserProfile(updatedProfile);

      if (!mounted) return;

      setState(() {
        _isEditing = false;
        _newProfileImage = null;
      });

      _showMessage('Profil mis à jour');
      await _loadProfile();
    } catch (e) {
      _showMessage('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2C),
        title: const Text(
          'Supprimer le compte ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Utilisateur non connecté');
        return;
      }

      // Supprimer le profil Firestore
      await _userService.deleteUserProfile(user.uid);

      // Supprimer le compte Firebase Auth
      // La suppression du compte déclenchera automatiquement authStateChanges
      // qui redirigera vers la page de connexion
      await user.delete();

      // Pas besoin de navigation manuelle, le StreamBuilder dans main.dart s'en charge
      // Le message sera affiché via ScaffoldMessenger global si nécessaire
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);

      if (e.code == 'requires-recent-login') {
        // Si la session est trop ancienne, demander à l'utilisateur de se reconnecter
        _showMessage('Votre session a expiré. Veuillez vous déconnecter et vous reconnecter avant de supprimer votre compte.');
      } else {
        _showMessage('Erreur Firebase: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Erreur: $e');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentProfile == null) {
      return SpaceBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.capsuleUnlocked),
          ),
        ),
      );
    }

    return SpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Mon profil',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier',
                onPressed: () => setState(() => _isEditing = true),
              )
            else
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Annuler',
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _newProfileImage = null;
                  });
                  _loadProfile();
                },
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: AnimatedLedBorder(
                borderRadius: AppSizes.radiusLarge,
                borderWidth: 2,
                glowIntensity: 10,
                animationDuration: const Duration(seconds: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.maxContentWidth,
                      ),
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      decoration: AppStyles.glassContainer(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Photo de profil
                          GestureDetector(
                            onTap: _isEditing && !_isLoading
                                ? _pickImage
                                : null,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.glassSurface
                                      .withOpacity(0.1),
                                  backgroundImage: _newProfileImage != null
                                      ? FileImage(_newProfileImage!)
                                      : (_currentProfile?.photoUrl != null
                                                ? NetworkImage(
                                                    _currentProfile!.photoUrl!,
                                                  )
                                                : null)
                                            as ImageProvider?,
                                  child:
                                      _newProfileImage == null &&
                                          _currentProfile?.photoUrl == null
                                      ? Text(
                                          _currentProfile?.initials ?? '',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        )
                                      : null,
                                ),
                                if (_isEditing)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.capsuleUnlocked,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email (non modifiable)
                          ListTile(
                            leading: const Icon(
                              Icons.email,
                              color: AppColors.textSecondary,
                            ),
                            title: Text(
                              _currentProfile?.email ?? '',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'Email',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Prénom
                          TextFormField(
                            controller: _firstNameController,
                            enabled: _isEditing && !_isLoading,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Prénom',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppColors.textSecondary,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMedium,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.glassSurface.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMedium,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.glassSurface.withOpacity(
                                    0.1,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMedium,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.capsuleUnlocked,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le prénom est requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          // Nom
                          TextFormField(
                            controller: _lastNameController,
                            enabled: _isEditing && !_isLoading,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Nom',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: AppColors.textSecondary,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMedium,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.glassSurface.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMedium,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.glassSurface.withOpacity(
                                    0.1,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMedium,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.capsuleUnlocked,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom est requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          // Date de naissance
                          InkWell(
                            onTap: _isEditing && !_isLoading
                                ? _pickBirthDate
                                : null,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMedium,
                            ),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date de naissance',
                                labelStyle: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                prefixIcon: const Icon(
                                  Icons.cake,
                                  color: AppColors.textSecondary,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.glassSurface.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.glassSurface.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                ),
                              ),
                              child: Text(
                                _birthDate == null
                                    ? 'Non renseignée'
                                    : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                                style: TextStyle(
                                  color: _birthDate == null
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          const SizedBox(height: 32),

                          // Boutons
                          if (_isEditing) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.capsuleUnlocked,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMedium,
                                    ),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Enregistrer',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _deleteAccount,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                    color: AppColors.error,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMedium,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Supprimer mon compte',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Politique de confidentialité
                            Center(
                              child: TextButton.icon(
                                onPressed: () async {
                                  final url = Uri.parse(
                                    'https://time-capsule-5ecb5.web.app/privacy-policy.html',
                                  );
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.privacy_tip_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                label: const Text(
                                  'Politique de confidentialité',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
