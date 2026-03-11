import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:soulmate/core/di/service_locator.dart';
import 'package:soulmate/domain/repositories/auth_repository.dart';
import 'package:soulmate/presentation/providers/theme_provider.dart';
import 'package:soulmate/presentation/providers/notification_provider.dart';
import 'package:soulmate/presentation/providers/profile_management_provider.dart';
import 'package:soulmate/presentation/screens/login_screen.dart';
import 'package:soulmate/presentation/screens/edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final auth = ServiceLocator.authRepository;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('Edit Profile', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text('Update Email', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUpdateEmailDialog(context, auth),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text('Change Password', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context, auth),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              'Delete Account',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
            onTap: () => _showDeleteAccountDialog(context, auth),
          ),
          const Divider(),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          SwitchListTile(
            title: Text(
              'Push Notifications',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: notificationProvider.areNotificationsEnabled,
            onChanged: (value) {
              notificationProvider.toggleNotifications(value);
            },
            secondary: Icon(
              notificationProvider.areNotificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: const Color(0xFFFE3C72),
            ),
            activeTrackColor: const Color(0xFFFE3C72),
          ),
          const Divider(),

          // Preferences Section
          _buildSectionHeader(context, 'Preferences'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Theme',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto, size: 20),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode, size: 20),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode, size: 20),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      themeProvider.setThemeMode(newSelection.first);
                    },
                    style: ButtonStyle(
                      side: WidgetStateProperty.all(
                        BorderSide(
                          color: const Color(0xFFFE3C72).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(
              Icons.rocket_launch_outlined,
              color: Color(0xFFFE3C72),
            ),
            title: Text(
              'About Soulmate',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Version 1.0.0 • Learn more',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text('Contact Us', style: GoogleFonts.poppins()),
            onTap: () => _showFeedbackDialog(context, auth),
          ),
          const Divider(),

          const SizedBox(height: 20),

          // WIPE DATA BUTTON (DEBUG ONLY)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showWipeDataDialog(context, auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'WIPE ALL DATA (DEBUG)',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Actions Section
          _buildSectionHeader(context, 'Actions'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text('Sign Out', style: GoogleFonts.poppins()),
            onTap: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFE3C72),
        ),
      ),
    );
  }

  void _showUpdateEmailDialog(
    BuildContext context,
    AuthRepository authRepository,
  ) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Email'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'New Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newEmail = emailController.text.trim();
              if (newEmail.isEmpty) return;

              try {
                // 1. Update Auth (sends verification)
                await authRepository.updateEmail(newEmail);

                // 2. Update Firestore immediately so UI reflects change
                final user = authRepository.currentUser;
                if (user != null) {
                  if (context.mounted) {
                    await context
                        .read<ProfileManagementProvider>()
                        .updateUserField(user.uid, {'email': newEmail});
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Verification email sent. Profile updated.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating email: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AuthRepository authRepository,
  ) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'New Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await authRepository.updatePassword(
                  passwordController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating password: $e')),
                  );
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    AuthRepository authRepository,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await authRepository.deleteAccount();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Image.asset('assets/images/logo_transparent.png', height: 60),
            const SizedBox(height: 12),
            Text(
              'Soulmate',
              style: GoogleFonts.pacifico(
                fontSize: 28,
                color: const Color(0xFFFE3C72),
              ),
            ),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Soulmate, your personalized dating assistant designed to help you find meaningful connections through shared interests and AI-driven compatibility.',
                style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE3C72).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Core Features',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFE3C72),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      Icons.psychology,
                      'Smart Matching Algorithm',
                    ),
                    _buildFeatureItem(
                      Icons.chat_bubble_outline,
                      'AI-Powered Conversations',
                    ),
                    _buildFeatureItem(
                      Icons.military_tech,
                      'Gamified Chat XP System',
                    ),
                    _buildFeatureItem(
                      Icons.security,
                      'Secure & Private Platform',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Made with ❤️ by the Soulmate Team',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE3C72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Text(
              'Awesome',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFE3C72)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      ),
    );
  }

  void _showFeedbackDialog(
    BuildContext context,
    AuthRepository authRepository,
  ) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Us'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We value your feedback! Let us know what you think or report any issues.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter your feedback here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final message = feedbackController.text.trim();
              if (message.isNotEmpty) {
                try {
                  final userId = authRepository.currentUser?.uid ?? 'anonymous';
                  if (context.mounted) {
                    await context
                        .read<ProfileManagementProvider>()
                        .saveFeedback(userId, message);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your feedback!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving feedback: $e')),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showWipeDataDialog(
    BuildContext context,
    AuthRepository authRepository,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: Text(
          'WIPE ALL DATA?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red[900],
          ),
        ),
        content: Text(
          'This will delete ALL users, chats, and feedback from Firestore. \n\nTHIS ACTION CANNOT BE UNDONE.',
          style: GoogleFonts.poppins(color: Colors.red[900]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await ServiceLocator.wipeAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data wiped successfully.'),
                    ),
                  );
                  // Logout user
                  await authRepository.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error wiping data: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('WIPE EVERYTHING', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
