import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../data/models/user_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/image_generation_service.dart';
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

  // Background Upload State
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;
  Future<String?>? _pendingUploadFuture;

  User? _currentUser;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _generatedAvatarUrl = null;
          _isUploadingImage = true; // Start spinner
          _uploadedImageUrl = null; // Reset previous upload
        });

        // START BACKGROUND UPLOAD IMMEDIATELY
        _startBackgroundUpload(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  void _startBackgroundUpload(File imageFile) {
    if (_currentUser == null) return;

    _pendingUploadFuture = StorageService()
        .uploadProfileImage(imageFile, _currentUser!.id)
        .then((url) {
          if (mounted) {
            setState(() {
              _isUploadingImage = false;
              _uploadedImageUrl = url;
            });
            if (url != null) {
              debugPrint("Background upload complete: $url");
            }
          }
          return url;
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _isUploadingImage = false;
              _uploadedImageUrl = null;
            });
            debugPrint("Background upload error: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        });
  }

  void _generateAIPortrait() {
    if (_currentUser == null) return;

    // Create a temporary user with current controller values to ensure prompt is up-to-date
    final tempUser = _currentUser!.copyWith(
      age: int.tryParse(_ageController.text) ?? _currentUser!.age,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      bio: _bioController.text,
    );

    setState(() {
      _isLoading = true;
      _isUploadingImage = true; // Reuse spinner for generation
    });

    // Simulate a short "thinking" delay for UX
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final url = ImageGenerationService.generateProfileImageUrl(tempUser);
      setState(() {
        _generatedAvatarUrl = url;
        _imageFile = null;
        _uploadedImageUrl = null;
        _isUploadingImage = false; // Stop spinner
        _isLoading = false;
      });
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome), // Magic icon
                title: const Text('Generate AI Portrait'), // Corrected title
                onTap: () {
                  Navigator.pop(context);
                  _generateAIPortrait();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String firestoreImageUrl = _currentUser?.imageUrl ?? '';
      String localDisplayImageUrl = firestoreImageUrl;

      // OPTIMIZED: Check if background upload is already done, or wait for it.
      if (_imageFile != null) {
        if (_uploadedImageUrl != null) {
          // Upload already finished successfully
          String rawUrl = _uploadedImageUrl!;
          // Append timestamp for cache busting locally
          localDisplayImageUrl =
              '$rawUrl&v=${DateTime.now().millisecondsSinceEpoch}';
        } else if (_pendingUploadFuture != null) {
          // Upload still in progress, await it
          final url = await _pendingUploadFuture;
          if (url != null) {
            String rawUrl = url;
            localDisplayImageUrl =
                '$rawUrl&v=${DateTime.now().millisecondsSinceEpoch}';
          } else {
            throw Exception("Image upload failed");
          }
        } else {
          // Fallback: Upload wasn't started for some reason (shouldn't happen with correct flow)
          final url = await StorageService().uploadProfileImage(
            _imageFile!,
            _currentUser!.id,
          );
          if (url != null) {
            localDisplayImageUrl =
                '$url&v=${DateTime.now().millisecondsSinceEpoch}';
          }
        }
      } else if (_generatedAvatarUrl != null) {
        localDisplayImageUrl = _generatedAvatarUrl!;
      }

      // Update User object
      final userForFirestore = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        imageUrl: localDisplayImageUrl,
        gender: _currentUser!.gender,
        interests: _currentUser!.interests,
        genderPreference: _currentUser!.genderPreference,
        bio: _bioController.text.trim(),
      );

      // Save to Firestore
      await DatabaseService().saveUser(userForFirestore);

      // Update Provider
      if (mounted) {
        Provider.of<UserProvider>(
          context,
          listen: false,
        ).updateLocalUser(userForFirestore);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile details updated successfully!'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
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
                onTap: _showImagePickerOptions,
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
                      child: _isUploadingImage
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFE3C72),
                              ),
                            )
                          : (_generatedAvatarUrl == null &&
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
                          Icons.camera_alt, // Changed to camera/edit icon
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
