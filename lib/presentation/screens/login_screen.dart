import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:soulmate/presentation/providers/login_provider.dart';
import 'package:soulmate/presentation/screens/gender_selection_screen.dart';
import 'package:soulmate/presentation/screens/register_screen.dart';

import 'package:soulmate/presentation/screens/create_profile_screen.dart';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _LoginHeader(),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _RememberMeCheckbox(rememberNotifier: _rememberMe),
                      const SizedBox(height: 24),
                      _SignInButton(
                        isLoading: loginProvider.isLoading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 16),
                      _RegisterLink(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const _SocialLoginDivider(),
                      const SizedBox(height: 20),
                      _SocialButtons(
                        isLoading: loginProvider.isLoading,
                        onGoogleTap: _handleGoogleLogin,
                        onAppleTap: _handleAppleLogin,
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
      // Login failed or cancelled — show provider error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loginProvider.errorMessage ?? 'Login failed')),
      );
      return;
    }

    if (isNewUser) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              CreateProfileScreen(firebaseUser: loginProvider.firebaseUser!),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final loginProvider = context.read<LoginProvider>();
    final isNewUser = await loginProvider.signInWithGoogle();
    _navigateAfterAuth(isNewUser);
  }

  Future<void> _handleAppleLogin() async {
    final loginProvider = context.read<LoginProvider>();
    final isNewUser = await loginProvider.signInWithApple();
    _navigateAfterAuth(isNewUser);
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Image.asset(
          'assets/images/logo_transparent.png',
          height: 80,
          width: 80,
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF80CBC4)
                : const Color(0xFF004D40),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Log in to find your soulmate.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
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
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: const InputDecoration(hintText: 'Email'),
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
    return ValueListenableBuilder<bool>(
      valueListenable: obscureNotifier,
      builder: (context, obscure, child) {
        return TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
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
        return Row(
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
              ),
            ),
          ],
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: const Text('Sign In'),
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
          'Do not have account? ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Register now',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialLoginDivider extends StatelessWidget {
  const _SocialLoginDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Login with Socials',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _SocialButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  const _SocialButtons({
    required this.isLoading,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SocialButton(
          iconWidget: Image.asset(
            'assets/images/google_logo.png',
            height: 20,
            width: 20,
          ),
          label: 'Sign In with Google',
          color: Colors.red,
          onTap: isLoading ? () {} : onGoogleTap,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          icon: FontAwesomeIcons.apple,
          label: 'Sign In with Apple',
          color: Colors.black,
          onTap: isLoading ? () {} : onAppleTap,
        ),
      ],
    );
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
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerTheme.color ?? Colors.grey[300]!,
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
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
