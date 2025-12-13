import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '/src/core/constants/app_constants.dart';
import '/src/core/widgets/space_background.dart';
import '../../data/user_service.dart';
import '../../domain/models/user_profile.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _profileImage;
  DateTime? _birthDate;
  bool _isLoading = false;

  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = UserService(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
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
        setState(() => _profileImage = File(picked.path));
      }
    } catch (e) {
      _showMessage('Erreur lors de la sélection de l\'image: $e');
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
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
    if (_profileImage == null) return null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance.ref().child(
        'profiles/${user.uid}/avatar.jpg',
      );

      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final photoUrl = await _uploadProfileImage();

      final profile = UserProfile(
        uid: user.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: user.email ?? '',
        photoUrl: photoUrl,
        birthDate: _birthDate,
        createdAt: DateTime.now(),
      );

      await _userService.createUserProfile(profile);

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      _showMessage('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SpaceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
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
                          Text(
                            'Créer votre profil',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Personnalisez votre aventure temporelle',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),

                          const SizedBox(height: 32),

                          // Photo de profil
                          GestureDetector(
                            onTap: _isLoading ? null : _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 68,
                                  backgroundColor: AppColors.glassSurface
                                      .withOpacity(0.2),
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : null,
                                  child: _profileImage == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 70,
                                          color: AppColors.textSecondary,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.capsuleUnlocked,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          _buildInputField(
                            controller: _firstNameController,
                            icon: Icons.person,
                            label: "Prénom",
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? "Requis" : null,
                          ),
                          const SizedBox(height: 20),

                          _buildInputField(
                            controller: _lastNameController,
                            icon: Icons.person_outline,
                            label: "Nom",
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? "Requis" : null,
                          ),
                          const SizedBox(height: 20),

                          _buildBirthdatePicker(),

                          const SizedBox(height: 40),

                          // Bouton
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
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
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Créer mon profil',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(
            color: AppColors.glassSurface.withOpacity(0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: const BorderSide(color: AppColors.capsuleUnlocked),
        ),
      ),
    );
  }

  Widget _buildBirthdatePicker() {
    return InkWell(
      onTap: _pickBirthDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Date de naissance (optionnel)",
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.cake, color: AppColors.textSecondary),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            borderSide: BorderSide(
              color: AppColors.glassSurface.withOpacity(0.25),
            ),
          ),
        ),
        child: Text(
          _birthDate == null
              ? "Sélectionner une date"
              : "${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}",
          style: TextStyle(
            color: _birthDate == null
                ? AppColors.textTertiary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
