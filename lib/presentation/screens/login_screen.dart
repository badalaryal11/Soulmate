import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:soulmate/data/datasources/auth_service.dart';
import 'package:soulmate/data/datasources/database_service.dart';
import 'package:soulmate/domain/entities/user.dart';
import 'package:soulmate/presentation/screens/gender_selection_screen.dart';
import 'package:soulmate/presentation/screens/register_screen.dart';

import 'package:soulmate/presentation/screens/create_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  final DatabaseService? databaseService;

  const LoginScreen({super.key, this.authService, this.databaseService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AuthService _authService;
  late final DatabaseService _databaseService;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _databaseService = widget.databaseService ?? DatabaseService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo or Header Image
                    Image.asset(
                      'assets/images/logo_transparent.png',
                      height: 80, // Reduced from 100
                      width: 80,
                    ),
                    const SizedBox(height: 16), // Reduced from 20
                    // Welcome Text
                    Text(
                      'Welcome!',
                      style: GoogleFonts.poppins(
                        fontSize: 24, // Reduced from 28
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF80CBC4)
                            : const Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 4), // Reduced from 8
                    Text(
                      'Log in to find your soulmate.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24), // Reduced from 40
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email or Mobile Number',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14, // Reduced from 16
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFE3C72),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Reduced from 20
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14, // Reduced from 16
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFE3C72),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8), // Reduced from 10
                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFE3C72),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Reduced from 20
                    // Remember Me Checkbox
                    Row(
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(0xFFFE3C72),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24), // Reduced from 40
                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 50, // Reduced from 55
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFE3C72), // Pink/Red
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: const Color(
                            0xFFFE3C72,
                          ).withValues(alpha: 0.4),
                        ),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            fontSize: 16, // Reduced from 18
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Reduced from 20
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Do not have account? ',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Register now',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFE3C72),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24), // Reduced from 40
                    // Social Login Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Login with Socials',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 20), // Reduced from 30
                    // Social Buttons
                    Column(
                      children: [
                        _SocialButton(
                          iconWidget: Image.asset(
                            'assets/images/google_logo.png',
                            height: 20,
                            width: 20,
                          ),
                          label: 'Sign In with Google',
                          color: Colors.red,
                          onTap: _isLoading ? () {} : _handleGoogleLogin,
                        ),
                        const SizedBox(height: 12), // Reduced from 16
                        _SocialButton(
                          icon: FontAwesomeIcons.apple,
                          label: 'Sign In with Apple',
                          color: Colors.black,
                          onTap: _isLoading ? () {} : _handleAppleLogin,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final credential = await _authService.signInWithGoogle();

      if (credential != null && credential.user != null) {
        final firebaseUser = credential.user!;

        // Check if user exists in Firestore
        User? existingUser = await _databaseService.getUser(firebaseUser.uid);

        if (existingUser == null) {
          // User does not exist, redirect to Create Profile
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CreateProfileScreen(
                firebaseUser: firebaseUser,
                databaseService: _databaseService,
              ),
            ),
          );
        } else {
          // User exists, proceed to Gender Selection (which acts as Home/Filter setup)
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const GenderSelectionScreen(),
            ),
          );
        }
      } else {
        // User cancelled or error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign in cancelled or configuration missing (Check SHA-1).',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Google Login Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);

    try {
      final credential = await _authService.signInWithApple();

      if (credential != null && credential.user != null) {
        final firebaseUser = credential.user!;

        // Check if user exists in Firestore
        User? existingUser = await _databaseService.getUser(firebaseUser.uid);

        if (existingUser == null) {
          // New user — redirect to Create Profile
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CreateProfileScreen(
                firebaseUser: firebaseUser,
                databaseService: _databaseService,
              ),
            ),
          );
        } else {
          // Existing user — proceed to Gender Selection
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const GenderSelectionScreen(),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple Sign-In was cancelled.')),
        );
      }
    } catch (e) {
      debugPrint("Apple Login Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Apple Sign-In failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (credential != null && credential.user != null) {
        final firebaseUser = credential.user!;
        User? existingUser = await _databaseService.getUser(firebaseUser.uid);

        if (existingUser == null) {
          // Account exists in Auth but not in Firestore (e.g. registration interrupted)
          // Redirect to Create Profile to complete setup
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CreateProfileScreen(
                firebaseUser: firebaseUser,
                databaseService: _databaseService,
              ),
            ),
          );
          return;
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const GenderSelectionScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    String? email = _emailController.text.trim();
    if (email.isEmpty) {
      email = await showDialog<String>(
        context: context,
        builder: (context) {
          String inputEmail = '';
          return AlertDialog(
            title: Text('Reset Password', style: GoogleFonts.poppins()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your email address to receive a password reset link.',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => inputEmail = value,
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, inputEmail),
                child: Text(
                  'Send Link',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFE3C72),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    if (email != null && email.isNotEmpty) {
      try {
        await _authService.sendPasswordResetEmail(email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.color,
    required this.onTap,
  }) : assert(
         icon != null || iconWidget != null,
         'Either icon or iconWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null)
              iconWidget!
            else
              Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
