import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/di/service_locator.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'gender_selection_screen.dart';

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
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String _selectedGender = 'Male';
  int _age = 18;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userRepository = ServiceLocator.userRepository;

    // Pre-fill from Firebase User if available
    final nameParts = (widget.firebaseUser.displayName ?? '').split(' ');
    if (nameParts.isNotEmpty) {
      _firstNameController.text = nameParts.first;
      if (nameParts.length > 1) {
        _lastNameController.text = nameParts.sublist(1).join(' ');
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = User(
        id: widget.firebaseUser.uid,
        email: widget.firebaseUser.email ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim(),
        gender: _selectedGender,
        age: _age,
        city: _cityController.text.trim(),
        country: '',
        interests: [],
        imageUrl:
            widget.firebaseUser.photoURL ?? 'assets/images/default_avatar.png',
      );

      await _userRepository.saveUser(user);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
      );
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

              // First Name
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

              // Last Name
              TextFormField(
                controller: _lastNameController,
                validator: (v) =>
                    v != null && v.trim().isEmpty ? 'Required' : null,
                decoration: InputDecoration(
                  labelText: 'Last Name',
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

              // Gender Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                items: ['Male', 'Female', 'Other'].map((g) {
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
