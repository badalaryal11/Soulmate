import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:soulmate/presentation/providers/login_provider.dart';
import 'package:soulmate/presentation/screens/gender_selection_screen.dart';
import 'package:soulmate/presentation/screens/register_screen.dart';

import 'package:soulmate/presentation/screens/create_profile_screen.dart';
import 'package:soulmate/presentation/screens/email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ValueNotifier<bool> _rememberMe = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _obscurePassword = ValueNotifier<bool>(true);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _rememberMe.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.watch<LoginProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32.0, // adjusted for vertical padding
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          const _LoginHeader(),
                          const SizedBox(height: 32),
                          
                          // Glassmorphic translucent container for the form
                          Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E222B).withValues(alpha: 0.65)
                                  : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF353A44).withValues(alpha: 0.5)
                                    : const Color(0xFFE7DCE0).withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.15 : 0.04,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _EmailInputField(
                                  controller: _emailController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _PasswordInputField(
                                  controller: _passwordController,
                                  obscureNotifier: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Combined Remember Me & Forgot Password Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _RememberMeCheckbox(rememberNotifier: _rememberMe),
                                    TextButton(
                                      onPressed: _handleForgotPassword,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(50, 30),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _SignInButton(
                                  isLoading: loginProvider.isLoading,
                                  onPressed: _handleLogin,
                                ),
                                const SizedBox(height: 24),
                                _buildDivider(theme),
                                const SizedBox(height: 20),
                                _buildSocialButtons(context, loginProvider),
                                const SizedBox(height: 24),
                                _RegisterLink(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or continue with',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context, LoginProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SocialButton(
          onPressed: provider.isLoading ? null : () => _handleGoogleSignIn(provider),
          child: const FaIcon(
            FontAwesomeIcons.google,
            color: Color(0xFFDB4437),
            size: 28,
          ),
        ),
        _SocialButton(
          onPressed: provider.isLoading ? null : () => _handleAppleSignIn(provider),
          child: FaIcon(
            FontAwesomeIcons.apple,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black,
            size: 28,
          ),
        ),
      ],
    );
  }

  /// Navigate based on the result from LoginProvider.
  /// isNewUser == true  → CreateProfileScreen
  /// isNewUser == false → GenderSelectionScreen
  /// isNewUser == null  → Show error SnackBar
  void _navigateAfterAuth(bool? isNewUser) {
    if (!mounted) return;
    final loginProvider = context.read<LoginProvider>();

    if (isNewUser == null) {
      // Login failed or cancelled
      if (loginProvider.errorMessage != null) {
        // Clean up "Exception: " prefix if present
        String displayMessage = loginProvider.errorMessage!;
        if (displayMessage.startsWith('Exception: ')) {
          displayMessage = displayMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(displayMessage)),
        );
      }
      return;
    }

    if (isNewUser) {
      final user = loginProvider.firebaseUser!;
      final isPasswordProvider = user.providerData.any(
        (p) => p.providerId == 'password',
      );

      if (isPasswordProvider && !user.emailVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const EmailVerificationScreen(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CreateProfileScreen(firebaseUser: user),
          ),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final loginProvider = context.read<LoginProvider>();
    final isNewUser = await loginProvider.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    _navigateAfterAuth(isNewUser);
  }

  Future<void> _handleGoogleSignIn(LoginProvider provider) async {
    final isNewUser = await provider.signInWithGoogle();
    _navigateAfterAuth(isNewUser);
  }

  Future<void> _handleAppleSignIn(LoginProvider provider) async {
    final isNewUser = await provider.signInWithApple();
    _navigateAfterAuth(isNewUser);
  }

  Future<void> _handleForgotPassword() async {
    final loginProvider = context.read<LoginProvider>();
    String? email = _emailController.text.trim();

    if (email.isEmpty) {
      email = await showDialog<String>(
        context: context,
        builder: (context) {
          String inputEmail = '';
          return AlertDialog(
            title: const Text('Reset Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your email address to receive a password reset link.',
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => inputEmail = value,
                  decoration: InputDecoration(
                    hintText: 'Email Address',
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
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, inputEmail),
                child: const Text('Send Link'),
              ),
            ],
          );
        },
      );
    }

    if (email != null && email.isNotEmpty) {
      final success = await loginProvider.sendPasswordResetEmail(email);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loginProvider.errorMessage ?? 'Failed to send reset email',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _SocialButton({
    this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2E37) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF353A44) : const Color(0xFFE7DCE0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  final Widget child;
  const _AmbientBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final color1 = const Color(0xFFFE3C72).withValues(alpha: isDark ? 0.08 : 0.05);
    final color2 = const Color(0xFFFFB44A).withValues(alpha: isDark ? 0.08 : 0.05);

    return Stack(
      children: [
        Container(
          color: theme.scaffoldBackgroundColor,
        ),
        Positioned(
          top: -80,
          left: -80,
          width: 320,
          height: 320,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color1, Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          width: 360,
          height: 360,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color2, Colors.transparent],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFFFE3C72).withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_transparent.png',
            height: 90,
            width: 90,
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [Color(0xFFFE3C72), Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            'Soulmate',
            style: GoogleFonts.lobster(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find your perfect connection.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmailInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _EmailInputField({required this.controller, this.validator});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.emailAddress,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Email',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }
}

class _PasswordInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueNotifier<bool> obscureNotifier;
  final String? Function(String?)? validator;

  const _PasswordInputField({
    required this.controller,
    required this.obscureNotifier,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: obscureNotifier,
      builder: (context, obscure, child) {
        return TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () {
                obscureNotifier.value = !obscure;
              },
            ),
          ),
        );
      },
    );
  }
}

class _RememberMeCheckbox extends StatelessWidget {
  final ValueNotifier<bool> rememberNotifier;

  const _RememberMeCheckbox({required this.rememberNotifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: rememberNotifier,
      builder: (context, remember, child) {
        return GestureDetector(
          onTap: () {
            rememberNotifier.value = !remember;
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: remember,
                  onChanged: (value) {
                    rememberNotifier.value = value ?? false;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final buttonRadius = BorderRadius.circular(16);

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFE3C72), Color(0xFFFF6B6B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: buttonRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFE3C72).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white60,
          shape: RoundedRectangleBorder(
            borderRadius: buttonRadius,
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  final VoidCallback onTap;

  const _RegisterLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Register now',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
