import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/interests.dart';
import '../providers/user_provider.dart';
import '../../data/datasources/auth_service.dart';
import 'home_screen.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final List<String> _selectedInterests = [];

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < 5) {
          _selectedInterests.add(interest);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can select up to 5 interests')),
          );
        }
      }
    });
  }

  Future<void> _handleContinue() async {
    final userProvider = context.read<UserProvider>();
    userProvider.setInterests(_selectedInterests);

    // Update interests in Firestore if logged in
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      if (mounted) {
        await context.read<UserProvider>().updateUserField(currentUser.uid, {
          'interests': _selectedInterests,
        });
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Interests',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select up to 5 interests to find better matches.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppInterests.list.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return ChoiceChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (_) => _toggleInterest(interest),
                        selectedColor: const Color(0xFFFE3C72),
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFFE3C72)
                                : Colors.grey[300]!,
                          ),
                        ),
                        // Remove default implementation padding/elevation locally if needed
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _selectedInterests.isNotEmpty
                      ? _handleContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE3C72),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _selectedInterests.isNotEmpty ? 5 : 0,
                    shadowColor: const Color(0xFFFE3C72).withValues(alpha: 0.4),
                  ),
                  child: Text(
                    'Continue (${_selectedInterests.length}/5)',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
