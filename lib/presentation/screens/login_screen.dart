import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../providers/user_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  width: 120,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Welcome to Soulmate',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFE3C72),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Who are you interested in meeting?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 50),
              _GenderButton(
                label: 'Women',
                icon: Icons.female,
                color: Colors.pinkAccent,
                onTap: () => _onGenderSelected(context, 'female'),
              ),
              const SizedBox(height: 20),
              _GenderButton(
                label: 'Men',
                icon: Icons.male,
                color: Colors.blueAccent,
                onTap: () => _onGenderSelected(context, 'male'),
              ),
              const SizedBox(height: 20),
              _GenderButton(
                label: 'Everyone',
                icon: Icons.people,
                color: Colors.purpleAccent,
                onTap: () => _onGenderSelected(context, null), // null for both
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onGenderSelected(BuildContext context, String? gender) {
    // Set preference and load users
    context.read<UserProvider>().loadUsers(gender: gender);

    // Navigate to Home
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2,
          ), // using withValues
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
