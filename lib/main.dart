import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/providers/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/services/notification_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  runApp(const SoulmateApp());
}

class SoulmateApp extends StatefulWidget {
  const SoulmateApp({super.key});

  @override
  State<SoulmateApp> createState() => _SoulmateAppState();
}

class _SoulmateAppState extends State<SoulmateApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for new links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    // Check if it's a reset password link
    // Firebase sends link like: https://.../?link=https://.../?mode=resetPassword&oobCode=...
    debugPrint('Received Deep Link: $uri');

    // Simple parsing logic: looks for oobCode and mode=resetPassword
    String? oobCode = uri.queryParameters['oobCode'];
    String? mode = uri.queryParameters['mode'];

    // If wrapped in a dynamic link, parameters might be inside the 'link' param
    if (uri.queryParameters.containsKey('link')) {
      final innerUri = Uri.parse(uri.queryParameters['link']!);
      oobCode ??= innerUri.queryParameters['oobCode'];
      mode ??= innerUri.queryParameters['mode'];
    }

    if (mode == 'resetPassword' && oobCode != null) {
      // Navigate to Reset Password Screen
      // Use a slight delay to ensure the app is ready if verified on cold start
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(oobCode: oobCode!),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Soulmate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFE3C72)),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
