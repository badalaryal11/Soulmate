import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../data/models/user_model.dart';
import '../../data/services/database_service.dart';
import '../providers/user_provider.dart';
import 'interest_selection_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;

  File? _imageFile;
  String? _generatedAvatarUrl;
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      await userProvider.loadCurrentUser();
    }

    _currentUser = userProvider.currentUser;

    if (_currentUser != null) {
      _firstNameController = TextEditingController(
        text: _currentUser?.firstName,
      );
      _lastNameController = TextEditingController(text: _currentUser?.lastName);
      _bioController = TextEditingController(text: _currentUser?.bio);
      _ageController = TextEditingController(
        text: _currentUser?.age.toString(),
      );
      _cityController = TextEditingController(text: _currentUser?.city);
      _countryController = TextEditingController(text: _currentUser?.country);

      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _generateRandomAvatar() {
    final randomSeed = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _generatedAvatarUrl =
          'https://api.dicebear.com/9.x/adventurer/png?seed=$randomSeed';
      _imageFile = null; // Clear file if we are using random avatar
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = _currentUser?.imageUrl ?? '';

      // Use generated avatar if set
      if (_generatedAvatarUrl != null) {
        imageUrl = _generatedAvatarUrl!;
      }
      // Keep existing logic for file upload just in case, or remove if fully replacing.
      // For now, if _imageFile is null (which it is for random avatar), this block is skipped.
      else if (_imageFile != null && _currentUser != null) {
        // Fallback or legacy support if needed, mostly unused now
        imageUrl = await DatabaseService().uploadProfileImage(
          _currentUser!.id,
          _imageFile!,
        );
      }

      // Update User object
      final updatedUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        imageUrl: imageUrl,
        gender: _currentUser!.gender,
        interests: _currentUser!.interests, // Interests managed separately
        genderPreference: _currentUser!.genderPreference,
        bio: _bioController.text.trim(),
      );

      // Save to Firestore
      await DatabaseService().saveUser(updatedUser);

      // Refresh Provider
      if (mounted) {
        await Provider.of<UserProvider>(
          context,
          listen: false,
        ).loadCurrentUser();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      debugPrint("Error updating profile (EditProfileScreen): $e");
      debugPrint("Stack trace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Clipboard copy (optional, requires services)
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFFFE3C72)),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _generateRandomAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _generatedAvatarUrl != null
                          ? NetworkImage(_generatedAvatarUrl!)
                          : (_imageFile != null
                                ? FileImage(_imageFile!)
                                : (_currentUser!.imageUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              _currentUser!.imageUrl,
                                            )
                                          : null)
                                      as ImageProvider?),
                      child:
                          (_generatedAvatarUrl == null &&
                              _imageFile == null &&
                              _currentUser!.imageUrl.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFE3C72),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shuffle,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Fields
              _buildTextField('First Name', _firstNameController),
              const SizedBox(height: 16),
              _buildTextField('Last Name', _lastNameController),
              const SizedBox(height: 16),
              _buildTextField('Bio', _bioController, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Age',
                      _ageController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('City', _cityController)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Country', _countryController),

              const SizedBox(height: 30),

              // Interests Link
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Interests',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                subtitle: Text(
                  _currentUser!.interests.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InterestSelectionScreen(),
                    ),
                  ).then((_) => _loadUserData()); // Reload after return
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (label == 'First Name' && (value == null || value.isEmpty)) {
          return 'First name is required';
        }
        if (label == 'Age' && (value == null || value.isEmpty)) {
          return 'Age is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFE3C72)),
        ),
      ),
    );
  }
}
