import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user_model.dart';
import '../../data/datasources/database_service.dart';
import 'gender_selection_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  final firebase_auth.User firebaseUser;
  final DatabaseService? databaseService;

  const CreateProfileScreen({
    super.key,
    required this.firebaseUser,
    this.databaseService,
  });

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  late final DatabaseService _databaseService;
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
    _databaseService = widget.databaseService ?? DatabaseService();

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
      String imageUrl = widget.firebaseUser.photoURL ?? '';

      // Fallback if no image available
      if (imageUrl.isEmpty) {
        imageUrl =
            'https://ui-avatars.com/api/?name=${_firstNameController.text}+${_lastNameController.text}&background=random';
      }

      final newUser = User(
        id: widget.firebaseUser.uid,
        email: widget.firebaseUser.email ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: _age,
        city: _cityController.text.trim(),
        country: '', // Optional or auto-detect later
        imageUrl: imageUrl,
        gender: _selectedGender, // Normalized roughly
        interests: [], // Will be set in next screens or defaults
        bio: _bioController.text.trim(),
        genderPreference: null, // Set in next screen
      );

      await _databaseService.saveUser(newUser);

      if (!mounted) return;

      // Navigate to Gender Selection (Preference)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Profile',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Placeholder
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.firebaseUser.photoURL != null
                      ? NetworkImage(widget.firebaseUser.photoURL!)
                      : null,
                  child: widget.firebaseUser.photoURL == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 32),

              // Name Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Age and Gender
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _age,
                      decoration: _buildInputDecoration('Age'),
                      items: List.generate(83, (index) => 18 + index)
                          .map(
                            (age) => DropdownMenuItem(
                              value: age,
                              child: Text('$age'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _age = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: _buildInputDecoration('Gender'),
                      items: ['Male', 'Female', 'Non-binary']
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedGender = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // City
              _buildTextField(
                controller: _cityController,
                label: 'City',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              // Bio
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                maxLines: 3,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Tell us about yourself' : null,
              ),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFFE3C72),
                  foregroundColor: Colors.white,
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
                    : Text(
                        'Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: _buildInputDecoration(label),
      style: GoogleFonts.poppins(),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey),
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
      filled: true,
      fillColor: Theme.of(context).cardColor,
    );
  }
}
