import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:soulmate/core/constants/app_constants.dart';
import 'package:soulmate/core/di/service_locator.dart';
import 'package:soulmate/domain/repositories/auth_repository.dart';
import 'package:soulmate/presentation/providers/theme_provider.dart';
import 'package:soulmate/presentation/providers/notification_provider.dart';
import 'package:soulmate/presentation/providers/profile_management_provider.dart';
import 'package:soulmate/presentation/screens/login_screen.dart';
import 'package:soulmate/presentation/screens/edit_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';


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
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
              'New Matches & Likes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: notificationProvider.matchesEnabled,
            onChanged: (value) {
              notificationProvider.toggleMatches(value);
            },
            secondary: Icon(
              notificationProvider.matchesEnabled
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: const Color(0xFFFE3C72),
            ),
            activeTrackColor: const Color(0xFFFE3C72),
          ),
          SwitchListTile(
            title: Text(
              'Messages & Activity',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: notificationProvider.messagesEnabled,
            onChanged: (value) {
              notificationProvider.toggleMessages(value);
            },
            secondary: Icon(
              notificationProvider.messagesEnabled
                  ? Icons.chat_bubble
                  : Icons.chat_bubble_outline,
              color: const Color(0xFFFE3C72),
            ),
            activeTrackColor: const Color(0xFFFE3C72),
          ),
          SwitchListTile(
            title: Text(
              'Engagement Reminders',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: notificationProvider.engagementEnabled,
            onChanged: (value) {
              notificationProvider.toggleEngagement(value);
            },
            secondary: Icon(
              notificationProvider.engagementEnabled
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
          _buildSectionHeader(context, 'Support & Legal'),
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
              'Version ${AppConstants.appVersion} • Learn more',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text('Contact Support', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFeedbackDialog(context, auth),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text('Official Website', style: GoogleFonts.poppins()),
            subtitle: Text('https://soulmateapp.link', style: GoogleFonts.poppins(fontSize: 12)),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchURL(context, 'https://soulmateapp.link'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLegalDialog(
              context, 
              'Privacy Policy', 
              'Your privacy is our priority. We only collect the data necessary to provide you with the best possible matches and experience. We never sell your personal data to third parties.\n\nFor a full list of our data practices, please visit our website.',
              url: 'https://soulmateapp.link/privacy.html',
            ),
          ),

          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text('Terms of Service', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLegalDialog(
              context, 
              'Terms of Service', 
              'By using Soulmate, you agree to treat all members with respect. Any form of harassment, hate speech, or inappropriate behavior will result in an immediate ban.\n\nBe kind, be authentic, and have fun!',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text('Community Guidelines', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLegalDialog(
              context, 
              'Community Guidelines', 
              '1. Be Yourself. No fake profiles or catfishing.\n2. Be Respectful. Harassment is zero tolerance.\n3. Keep it Safe. Do not share financial info.\n4. Communicate Clearly. Use the AI to help break the ice!\n\nHelp us keep Soulmate a safe place for everyone.',
            ),
          ),
          const Divider(),

          const SizedBox(height: 20),

          // WIPE DATA BUTTON — only rendered in debug builds
          if (kDebugMode) ...[  
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
          ],

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

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching link: $e')),
        );
      }
    }
  }  void _showDeleteAccountDialog(
    BuildContext context,
    AuthRepository authRepository,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteAccountDialog(authRepository: authRepository),
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
              'Version ${AppConstants.appVersion}',
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
          OutlinedButton.icon(
            icon: const Icon(Icons.language, size: 16, color: Color(0xFFFE3C72)),
            label: Text(
              'Visit Website',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFE3C72),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFE3C72)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              Navigator.pop(context);
              _launchURL(context, 'https://soulmateapp.link');
            },
          ),
          const SizedBox(width: 8),
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


  void _showLegalDialog(BuildContext context, String title, String content, {String? url}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              ),
              if (url != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16, color: Color(0xFFFE3C72)),
                    label: Text(
                      'Read Full Policy Online',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFE3C72),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _launchURL(context, url);
                    },
                  ),
                ),
              ],
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
    showDialog(
      context: context,
      builder: (context) => _FeedbackDialog(authRepository: authRepository),
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

/// Wrapper that shows the "Account Deleted" success dialog on top of
/// LoginScreen. Using a separate StatefulWidget ensures the dialog is
/// shown in a clean navigation context, free of the old provider tree.
class _AccountDeletedLoginScreen extends StatefulWidget {
  const _AccountDeletedLoginScreen();

  @override
  State<_AccountDeletedLoginScreen> createState() =>
      _AccountDeletedLoginScreenState();
}

class _AccountDeletedLoginScreenState
    extends State<_AccountDeletedLoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (successContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Account Deleted'),
          content: const Text('Your account is successfully deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(successContext),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFFFE3C72),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}

class _DeleteAccountDialog extends StatefulWidget {
  final AuthRepository authRepository;
  const _DeleteAccountDialog({required this.authRepository});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late final TextEditingController _emailController;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = widget.authRepository.currentUser?.email ?? '';
    final expectedConfirmation = currentUserEmail.isNotEmpty ? currentUserEmail : 'DELETE';

    return AlertDialog(
      title: const Text('Delete Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete your account? This action cannot be undone.\n\n'
            '${currentUserEmail.isNotEmpty ? 'Please enter your email to confirm:' : 'Please type DELETE to confirm:'}',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            enabled: !_isDeleting,
            decoration: InputDecoration(
              hintText: currentUserEmail.isNotEmpty ? currentUserEmail : 'DELETE',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: _isDeleting
          ? [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final enteredText = _emailController.text.trim();
                  if (enteredText != expectedConfirmation) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(currentUserEmail.isNotEmpty
                            ? 'Email does not match. Confirmation failed.'
                            : 'Confirmation failed. Please type DELETE.'),
                      ),
                    );
                    return;
                  }

                  final lastSignInTime = widget.authRepository.currentUser?.metadata.lastSignInTime;
                  final isStale = lastSignInTime == null ||
                      DateTime.now().difference(lastSignInTime).inMinutes > 5;

                  if (isStale) {
                    Navigator.pop(context);
                    await widget.authRepository.signOut();
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('For security, please log in again to delete your account.'),
                        duration: Duration(seconds: 5),
                        backgroundColor: Colors.orange,
                      ),
                    );

                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                    return;
                  }

                  setState(() {
                    _isDeleting = true;
                  });

                  try {
                    final uid = widget.authRepository.currentUser?.uid;
                    if (uid != null) {
                      await ServiceLocator.userRepository.deleteUser(uid);
                    }
                    await widget.authRepository.deleteAccount();

                    if (!context.mounted) return;
                    
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const _AccountDeletedLoginScreen(),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    
                    if (e.toString().contains('requires-recent-login')) {
                      Navigator.pop(context);
                      await widget.authRepository.signOut();
                      if (!context.mounted) return;
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Session expired. Please log in again to delete your account.'),
                          duration: Duration(seconds: 5),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    } else {
                      setState(() {
                        _isDeleting = false;
                      });
                      
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
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  final AuthRepository authRepository;
  const _FeedbackDialog({required this.authRepository});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  late final TextEditingController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            controller: _feedbackController,
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
            final message = _feedbackController.text.trim();
            if (message.isNotEmpty) {
              try {
                final userId = widget.authRepository.currentUser?.uid ?? 'anonymous';
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
    );
  }
}
