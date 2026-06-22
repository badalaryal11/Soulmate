import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/di/service_locator.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/user_avatar.dart';
// Removed: import 'gender_selection_screen.dart';

import '../../core/utils/image_generation_service.dart';
import 'user_gender_selection_screen.dart';
import 'email_verification_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  final firebase_auth.User firebaseUser;

  const CreateProfileScreen({super.key, required this.firebaseUser});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  late final UserRepository _userRepository;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _selectedAvatarUrl;

  String _selectedGender = 'Male';
  int _age = 18;
  bool _isLoading = false;
  
  // Background Upload State
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;
  Future<String?>? _pendingUploadFuture;

  @override
  void initState() {
    super.initState();
    _userRepository = ServiceLocator.userRepository;

    // Pre-fill from Firebase User if available
    final nameParts = (widget.firebaseUser.displayName ?? '').split(' ');
    if (nameParts.isNotEmpty) {
      _firstNameController.text = nameParts.first;
    }

    // Use Google profile photo as default avatar if available
    if (widget.firebaseUser.photoURL != null &&
        widget.firebaseUser.photoURL!.isNotEmpty) {
      _selectedAvatarUrl = widget.firebaseUser.photoURL;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _generateAIPortrait() {
    final tempUser = User(
      id: widget.firebaseUser.uid,
      email: widget.firebaseUser.email ?? '',
      firstName: _firstNameController.text.trim(),
      lastName: '',
      bio: _bioController.text.trim(),
      gender: _selectedGender,
      age: _age,
      city: _cityController.text.trim(),
      country: _countryController.text.trim(),
      interests: [],
      imageUrl: '',
      lastLoginDate: DateTime.now().toIso8601String(),
      badges: [],
      favoriteUserIds: [],
      pinnedUserIds: [],
    );
    final url = ImageGenerationService.generateHighQualityPortrait(tempUser);

    setState(() {
      _selectedAvatarUrl = url;
      _imageFile = null;
      _uploadedImageUrl = null;
      _isUploadingImage = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (image != null) {
      if (!mounted) return;
      setState(() {
        _imageFile = File(image.path);
        _selectedAvatarUrl = null;
        _uploadedImageUrl = null;
        _isUploadingImage = true;

        _pendingUploadFuture = _userRepository
            .uploadProfileImage(
              widget.firebaseUser.uid, 
              _imageFile,
              userName: _firstNameController.text.trim(),
              email: widget.firebaseUser.email,
            )
            .then((url) {
          if (mounted) {
            setState(() {
              _uploadedImageUrl = url;
              _isUploadingImage = false;
              _pendingUploadFuture = null;
            });
          }
          return url;
        }).catchError((e) {
          if (mounted) {
            setState(() {
              _isUploadingImage = false;
              _pendingUploadFuture = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: $e')),
            );
          }
          throw e;
        });
      });
    }
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
                title: const Text('Upload from Device'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_view),
                title: const Text('Choose Avatar'),
                onTap: () {
                  Navigator.pop(context);
                  _showAvatarSelectionSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Generate AI Portrait'),
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

  void _showAvatarSelectionSheet() {
    final List<String> avatarSeeds = List.generate(
      30,
      (index) => 'seed_${DateTime.now().millisecondsSinceEpoch}_$index',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Choose an Avatar',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: avatarSeeds.length,
                    itemBuilder: (context, index) {
                      final seed = avatarSeeds[index];
                      final url =
                          'https://api.dicebear.com/9.x/adventurer/png?seed=$seed';
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarUrl = url;
                            _imageFile = null;
                            _uploadedImageUrl = null;
                            _isUploadingImage = false;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                            color: Colors.grey[100],
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: url,
                              memCacheWidth: 200,
                              maxWidthDiskCache: 200,
                              placeholder: (context, url) => const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl =
          widget.firebaseUser.photoURL ?? 'assets/images/logo_transparent.png';

      // Handle picked image from device
      if (_imageFile != null) {
        if (_uploadedImageUrl != null) {
          imageUrl = _uploadedImageUrl!;
        } else if (_pendingUploadFuture != null) {
          final url = await _pendingUploadFuture;
          if (url != null) {
            imageUrl = url;
          } else {
            throw Exception("Image upload failed");
          }
        } else {
          imageUrl = await _userRepository.uploadProfileImage(
            widget.firebaseUser.uid,
            _imageFile,
            userName: _firstNameController.text.trim(),
            email: widget.firebaseUser.email,
          );
        }
      } else if (_selectedAvatarUrl != null) {
        imageUrl = _selectedAvatarUrl!;
      }

      final user = User(
        id: widget.firebaseUser.uid,
        email: widget.firebaseUser.email ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: '',
        bio: _bioController.text.trim(),
        gender: _selectedGender,
        age: _age,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        interests: [],
        imageUrl: imageUrl,
        lastLoginDate: DateTime.now().toIso8601String(),
        badges: [],
        favoriteUserIds: [],
        pinnedUserIds: [],
      );

      await _userRepository.saveUser(user);

      if (!mounted) return;

      // Only enforce email verification for password users
      final isPasswordProvider = widget.firebaseUser.providerData.any(
        (p) => p.providerId == 'password',
      );

      if (isPasswordProvider && !widget.firebaseUser.emailVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const EmailVerificationScreen(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const UserGenderSelectionScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Tell us about yourself',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This information will be shown on your profile.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Profile Picture
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Stack(
                    children: [
                      UserAvatar(
                        radius: 80,
                        firstName: _firstNameController.text,
                        lastName: '',
                        imageUrl: _selectedAvatarUrl,
                        useRoundShape: true,
                        overrideImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : null,
                      ),
                      if (_isUploadingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.2),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFE3C72),
                                ),
                              ),
                            ),
                          ),
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
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to add a photo',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _firstNameController,
                validator: (v) =>
                    v != null && v.trim().isEmpty ? 'Required' : null,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Country
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: 'Country',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                items: ['Male', 'Female', 'Non-binary'].map((g) {
                  return DropdownMenuItem(value: g, child: Text(g));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedGender = v);
                },
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Age Slider
              Text(
                'Age: $_age',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: _age.toDouble(),
                min: 18,
                max: 100,
                divisions: 82,
                label: _age.toString(),
                onChanged: (v) => setState(() => _age = v.round()),
              ),
              const SizedBox(height: 24),

              // Theme Selection
              Text(
                'App Theme',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        themeProvider.setThemeMode(newSelection.first);
                      },
                      style: ButtonStyle(
                        side: WidgetStateProperty.all(
                          BorderSide(
                            color: const Color(
                              0xFFFE3C72,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE3C72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
