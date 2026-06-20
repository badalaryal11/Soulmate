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
import 'package:soulmate/presentation/providers/current_user_provider.dart';
import 'package:soulmate/presentation/providers/discovery_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final auth = ServiceLocator.authRepository;
    final currentUserProvider = Provider.of<CurrentUserProvider>(context);
    final profileProvider = Provider.of<ProfileManagementProvider>(context, listen: false);
    final discoveryProvider = Provider.of<DiscoveryProvider>(context);

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

          // Discovery Preferences Section
          _buildSectionHeader(context, 'Discovery Preferences'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Age Range',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${discoveryProvider.minAge.round()} - ${discoveryProvider.maxAge.round()}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFE3C72),
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(discoveryProvider.minAge, discoveryProvider.maxAge),
                  min: 18,
                  max: 100,
                  divisions: 82,
                  activeColor: const Color(0xFFFE3C72),
                  inactiveColor: Colors.grey.withValues(alpha: 0.3),
                  onChanged: (values) {
                    discoveryProvider.updateAgeRange(values.start, values.end);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Show Me',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Male',
                        label: Text('Men'),
                      ),
                      ButtonSegment(
                        value: 'Female',
                        label: Text('Women'),
                      ),
                      ButtonSegment(
                        value: 'Everyone',
                        label: Text('Everyone'),
                      ),
                    ],
                    selected: {currentUserProvider.currentUser?.genderPreference ?? 'Everyone'},
                    onSelectionChanged: (Set<String> newSelection) async {
                      final selected = newSelection.first;
                      final currentUser = currentUserProvider.currentUser;
                      if (currentUser != null) {
                        // Optimistic update locally
                        currentUserProvider.updateLocalUser(
                          currentUser.copyWith(genderPreference: selected)
                        );
                        // Persist to backend
                        await profileProvider.updateUserField(
                          currentUser.id, 
                          {'genderPreference': selected}
                        );
                        // Reload the deck with the new preference
                        discoveryProvider.loadUsers(gender: selected, clearList: true);
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFFFE3C72).withValues(alpha: 0.1);
                          }
                          return Colors.transparent;
                        },
                      ),
                      iconColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          return states.contains(WidgetState.selected) 
                            ? const Color(0xFFFE3C72) 
                            : Colors.grey;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLegalDialog(
              context, 
              'Privacy Policy', 
              'Your privacy is our priority. We only collect the data necessary to provide you with the best possible matches and experience. We never sell your personal data to third parties.\n\nFor a full list of our data practices, please visit our website.',
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

  void _showDeleteAccountDialog(
    BuildContext context,
    AuthRepository authRepository,
  ) {
    final emailController = TextEditingController();
    final currentUserEmail = authRepository.currentUser?.email ?? '';
    bool isDeleting = false;
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while deleting
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Delete Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to delete your account? This action cannot be undone.\n\n'
                  'Please enter your email to confirm:',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  enabled: !isDeleting,
                  decoration: InputDecoration(
                    hintText: currentUserEmail.isNotEmpty ? currentUserEmail : 'Your Email',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: isDeleting
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  ]
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final enteredEmail = emailController.text.trim();
                        if (enteredEmail != currentUserEmail) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Email does not match. Confirmation failed.')),
                          );
                          return;
                        }

                        // Set deleting state to show spinner inside dialog
                        setState(() {
                          isDeleting = true;
                        });

                        try {
                          await authRepository.deleteAccount();

                          if (!context.mounted) return;
                          
                          // Once deleted, clear all routes and navigate to Login
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const _AccountDeletedLoginScreen(),
                            ),
                            (route) => false,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          
                          if (e.toString().contains('requires-recent-login')) {
                            // Close the dialog
                            Navigator.pop(dialogContext);
                            
                            // Sign out the user
                            await authRepository.signOut();
                            
                            if (!context.mounted) return;
                            
                            // Show persistent snackbar at root level
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Session expired. Please log in again to delete your account.'),
                                duration: Duration(seconds: 5),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            
                            // Navigate to login
                            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          } else {
                            // Restore UI for other errors
                            setState(() {
                              isDeleting = false;
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
      ),
    ).then((_) => emailController.dispose());
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

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
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
    ).then((_) => feedbackController.dispose());
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
