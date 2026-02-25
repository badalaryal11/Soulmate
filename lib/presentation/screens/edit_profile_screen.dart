import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'dart:io';

import '../../domain/entities/user_model.dart';
import '../../data/datasources/database_service.dart';
import '../../data/datasources/image_generation_service.dart';
import '../providers/user_provider.dart';
import 'interest_selection_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/image_utils.dart';

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
  final ImagePicker _picker = ImagePicker();

  String? _selectedPrompt1;
  late TextEditingController _prompt1AnswerController;
  String? _selectedPrompt2;
  late TextEditingController _prompt2AnswerController;

  final List<String> _promptOptions = [
    'My ideal first date is...',
    'A shower thought I recently had...',
    'I geek out on...',
    'Two truths and a lie:',
    'The quickest way to my heart is...',
    'My most controversial opinion is...',
  ];

  String? _selectedGender;

  File? _imageFile;
  String? _generatedAvatarUrl;
  bool _isLoading = false;

  // Background Upload State
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;
  Future<String?>? _pendingUploadFuture;

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
      _selectedGender = _currentUser?.gender;

      _prompt1AnswerController = TextEditingController();
      _prompt2AnswerController = TextEditingController();

      if (_currentUser != null && _currentUser!.prompts.isNotEmpty) {
        _selectedPrompt1 = _currentUser!.prompts[0]['question'];
        _prompt1AnswerController.text =
            _currentUser!.prompts[0]['answer'] ?? '';
      }
      if (_currentUser != null && _currentUser!.prompts.length > 1) {
        _selectedPrompt2 = _currentUser!.prompts[1]['question'];
        _prompt2AnswerController.text =
            _currentUser!.prompts[1]['answer'] ?? '';
      }

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
    _prompt1AnswerController.dispose();
    _prompt2AnswerController.dispose();
    super.dispose();
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
      final url = ImageGenerationService.generateHighQualityPortrait(tempUser);
      setState(() {
        _generatedAvatarUrl = url;
        _imageFile = null;
        _uploadedImageUrl = null;
        _isUploadingImage = false; // Stop spinner
        _isLoading = false;
      });
    });
  }

  int _calculateCompletion() {
    if (_currentUser == null) return 0;
    int score = 0;
    if (_currentUser!.firstName.isNotEmpty) score += 10;
    if (_currentUser!.lastName.isNotEmpty) score += 10;
    if (_currentUser!.age > 0) score += 10;
    if (_currentUser!.gender.isNotEmpty) score += 10;
    if (_currentUser!.imageUrl.isNotEmpty) score += 20;
    if (_currentUser!.bio != null && _currentUser!.bio!.isNotEmpty) score += 10;
    if (_currentUser!.city.isNotEmpty && _currentUser!.country.isNotEmpty) {
      score += 10;
    }
    if (_currentUser!.interests.isNotEmpty) score += 10;
    if (_currentUser!.prompts.isNotEmpty) score += 10;
    return score;
  }

  Widget _buildCompletionMeter() {
    int percent = _calculateCompletion();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile Completion',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$percent%',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFE3C72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percent == 100 ? Colors.green : const Color(0xFFFE3C72),
            ),
            minHeight: 10,
          ),
        ),
        if (percent < 100) ...[
          const SizedBox(height: 8),
          Text(
            'Complete your profile to get more matches!',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ],
    );
  }

  void _showAvatarSelectionSheet() {
    // Generate 30 random seeds for the grid
    final List<String> avatarSeeds = List.generate(
      30,
      (index) => 'seed_${DateTime.now().millisecondsSinceEpoch}_$index',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height
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
                            _generatedAvatarUrl = url;
                            _imageFile = null;
                            _uploadedImageUrl = null;
                            _isUploadingImage = false;
                          });
                          Navigator.pop(context); // Close sheet
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
                              memCacheWidth: 200, // Optimize for grid item
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      setState(() {
        _imageFile = File(image.path);
        _generatedAvatarUrl = null;
        _uploadedImageUrl = null;
        // The background upload starts immediately in _saveProfile or similar flows if needed
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
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload from Device'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
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
          // Device upload - save locally instead of Firebase Storage
          final appDir = await getApplicationDocumentsDirectory();
          final fileName =
              '${_currentUser!.id}_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final localFile = File('${appDir.path}/$fileName');
          await _imageFile!.copy(localFile.path);
          localDisplayImageUrl = 'file://${localFile.path}';
        }
      } else if (_generatedAvatarUrl != null) {
        localDisplayImageUrl = _generatedAvatarUrl!;
      }

      List<Map<String, String>> newPrompts = [];
      if (_selectedPrompt1 != null &&
          _prompt1AnswerController.text.isNotEmpty) {
        newPrompts.add({
          'question': _selectedPrompt1!,
          'answer': _prompt1AnswerController.text.trim(),
        });
      }
      if (_selectedPrompt2 != null &&
          _prompt2AnswerController.text.isNotEmpty) {
        newPrompts.add({
          'question': _selectedPrompt2!,
          'answer': _prompt2AnswerController.text.trim(),
        });
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
        gender: _selectedGender ?? _currentUser!.gender,
        interests: _currentUser!.interests,
        genderPreference: _currentUser!.genderPreference,
        bio: _bioController.text.trim(),
        prompts: newPrompts,
        streak: _currentUser!.streak,
        coins: _currentUser!.coins,
        lastLoginDate: _currentUser!.lastLoginDate,
        badges: _currentUser!.badges,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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
              _buildCompletionMeter(),
              const SizedBox(height: 30),
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
                                      ? ImageUtils.getImageProvider(
                                          _currentUser!.imageUrl,
                                          maxWidth: 300,
                                        )
                                      : null)),
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
                    flex: 2,
                    child: _buildTextField(
                      'Age',
                      _ageController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
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
                          borderSide: const BorderSide(
                            color: Color(0xFFFE3C72),
                          ),
                        ),
                      ),
                      items: ['Male', 'Female', 'Non-binary']
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('City', _cityController),
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
              const SizedBox(height: 30),

              // Profile Prompts
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profile Prompts',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPromptSelector(
                1,
                _selectedPrompt1,
                _prompt1AnswerController,
                (val) => setState(() => _selectedPrompt1 = val),
              ),
              const SizedBox(height: 20),
              _buildPromptSelector(
                2,
                _selectedPrompt2,
                _prompt2AnswerController,
                (val) => setState(() => _selectedPrompt2 = val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptSelector(
    int index,
    String? selectedValue,
    TextEditingController controller,
    Function(String?) onChanged,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
            isExpanded: true,
            initialValue: selectedValue,
            hint: Text(
              'Select Prompt $index',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            decoration: const InputDecoration(border: InputBorder.none),
            items: _promptOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          if (selectedValue != null) ...[
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 2,
              style: GoogleFonts.poppins(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Your answer...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
            ),
          ],
        ],
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
