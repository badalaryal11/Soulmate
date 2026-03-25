import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'core/di/service_locator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/providers/current_user_provider.dart';
import 'presentation/providers/profile_management_provider.dart';
import 'presentation/providers/match_provider.dart';
import 'presentation/providers/discovery_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable HTTP fetching for Google Fonts to ensure new fonts like Lobster load correctly
  GoogleFonts.config.allowRuntimeFetching = true;

  PaintingBinding.instance.imageCache.maximumSizeBytes =
      100 * 1024 * 1024; // 100MB Cache

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable edge-to-edge mode (moved from SplashScreen)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidPlayIntegrityProvider(),
    providerApple: const AppleDeviceCheckProvider(),
  );

  // Configure Firestore cache to prevent unbounded local storage growth
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 40 * 1024 * 1024, // 40MB cache limit
  );

  await ServiceLocator.notificationRepository.initialize();
  runApp(const SoulmateApp());
}

class SoulmateApp extends StatefulWidget {
  const SoulmateApp({super.key});

  @override
  State<SoulmateApp> createState() => _SoulmateAppState();
}

class _SoulmateAppState extends State<SoulmateApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache critical application assets
    precacheImage(
      const AssetImage('assets/images/logo_transparent.png'),
      context,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is backgrounded
        debugPrint('App lifecycle: $state — resources paused');
        SharedPreferences.getInstance().then((prefs) {
          final engagementEnabled = prefs.getBool('notifications_engagement') ?? true;
          if (engagementEnabled) {
            ServiceLocator.notificationRepository.scheduleNotification(
              id: 99,
              title: "It's busy tonight! 🔥",
              body: "Hop on to find your match before they're gone.",
              delay: const Duration(hours: 2),
            );
          }
        }).catchError((e) {
          debugPrint('Error scheduling engagement notification: $e');
        });
        break;
      case AppLifecycleState.resumed:
        debugPrint('App lifecycle: resumed — resources active');
        ServiceLocator.notificationRepository.cancelNotification(99);
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        debugPrint('App lifecycle: $state');
        break;
    }
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
    // Cache text themes to avoid re-computation on every rebuild
    final poppinsLight = GoogleFonts.poppinsTextTheme();
    final poppinsDark = GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ServiceLocator.createCurrentUserProvider(),
        ),
        ChangeNotifierProxyProvider<
          CurrentUserProvider,
          ProfileManagementProvider
        >(
          create: (context) => ServiceLocator.createProfileManagementProvider(
            Provider.of<CurrentUserProvider>(context, listen: false),
          ),
          update: (_, currentUser, previous) =>
              previous ??
              ServiceLocator.createProfileManagementProvider(currentUser),
        ),
        ChangeNotifierProxyProvider<CurrentUserProvider, MatchProvider>(
          create: (context) => ServiceLocator.createMatchProvider(
            Provider.of<CurrentUserProvider>(context, listen: false),
          ),
          update: (_, currentUser, previous) =>
              previous ?? ServiceLocator.createMatchProvider(currentUser),
        ),
        ChangeNotifierProxyProvider<CurrentUserProvider, DiscoveryProvider>(
          create: (context) => ServiceLocator.createDiscoveryProvider(
            Provider.of<CurrentUserProvider>(context, listen: false),
          ),
          update: (_, currentUser, previous) =>
              previous ?? ServiceLocator.createDiscoveryProvider(currentUser),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            notificationRepository: ServiceLocator.notificationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceLocator.createChatProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceLocator.createLoginProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Soulmate',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFE3C72),
              ),
              textTheme: poppinsLight,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFE3C72)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE3C72),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFFFE3C72).withValues(alpha: 0.4),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFE3C72),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFFE3C72);
                  }
                  return null;
                }),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              dividerTheme: DividerThemeData(color: Colors.grey[300]),
            ),
            darkTheme: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFE3C72),
                brightness: Brightness.dark,
              ),
              textTheme: poppinsDark,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[800],
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFE3C72)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE3C72),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFFFE3C72).withValues(alpha: 0.4),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFE3C72),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFFE3C72);
                  }
                  return null;
                }),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              dividerTheme: DividerThemeData(color: Colors.grey[700]),
            ),
            home: ServiceLocator.authRepository.currentUser != null
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
