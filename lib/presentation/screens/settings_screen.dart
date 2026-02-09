import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AuthService? authService;
  final DatabaseService? databaseService;

  const SettingsScreen({super.key, this.authService, this.databaseService});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final auth = authService ?? AuthService();
    final db = databaseService ?? DatabaseService();

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
          SwitchListTile(
            title: Text(
              'Dark Mode',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: const Color(0xFFFE3C72),
            ),
            activeTrackColor: const Color(0xFFFE3C72),
          ),
          const Divider(),

          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('About Soulmate', style: GoogleFonts.poppins()),
            onTap: () => _showAboutDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text('Contact Us', style: GoogleFonts.poppins()),
            onTap: () => _showFeedbackDialog(context, auth, db),
          ),
          const Divider(),

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

  void _showUpdateEmailDialog(BuildContext context, AuthService authService) {
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
              try {
                await authService.updateEmail(emailController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Verification email sent to new address. Please verify to update.',
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
    AuthService authService,
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
                await authService.updatePassword(
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

  void _showDeleteAccountDialog(BuildContext context, AuthService authService) {
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
                await authService.deleteAccount();
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
        title: Row(
          children: [
            Image.asset('assets/images/logo_transparent.png', height: 40),
            const SizedBox(width: 10),
            Text(
              'Soulmate',
              style: GoogleFonts.pacifico(
                fontSize: 24,
                color: const Color(0xFFFE3C72),
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
                'Version 1.0.0',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Soulmate is a dating app designed to help you find meaningful connections based on shared interests and personality compatibility.',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 10),
              Text(
                'Features:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text('• Smart Matching Algorithm', style: GoogleFonts.poppins()),
              const SizedBox(height: 5),
              Text(
                '• AI-Powered Conversations: Experience engaging conversations with our advanced AI models tailored to your personality.',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 5),
              Text(
                '• Gamified Chat Experience: Level up your connection just by chatting! Earn XP for every message and unlock new relationship status levels.',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 5),
              Text('• Personalized Profiles', style: GoogleFonts.poppins()),
              Text('• Secure & Private', style: GoogleFonts.poppins()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(
    BuildContext context,
    AuthService authService,
    DatabaseService dbService,
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
                  final userId = authService.currentUser?.uid ?? 'anonymous';
                  await dbService.saveFeedback(userId, message);

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
}
