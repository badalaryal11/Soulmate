import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/usecases/get_chat_id_usecase.dart';
import 'domain/usecases/get_chat_stream_usecase.dart';
import 'domain/usecases/get_message_history_usecase.dart';
import 'domain/usecases/send_message_usecase.dart';
import 'domain/usecases/mark_messages_as_read_usecase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/datasources/notification_service.dart';
import 'data/datasources/auth_service.dart';
import 'data/datasources/database_service.dart';
import 'data/datasources/chat_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      100 * 1024 * 1024; // 100MB Cache

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

  // Configure Firestore cache to prevent unbounded local storage growth
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 40 * 1024 * 1024, // 40MB cache limit
  );

  await NotificationService().initialize();
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
        // App is backgrounded — Firestore listeners auto-pause,
        // image cache is managed by CachedNetworkImage
        debugPrint('App lifecycle: $state — resources paused');
        break;
      case AppLifecycleState.resumed:
        debugPrint('App lifecycle: resumed — resources active');
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
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final databaseService = DatabaseService();
            final chatRepository = ChatRepositoryImpl(databaseService);
            return ChatProvider(
              chatService: ChatService(),
              notificationService: NotificationService(),
              getChatIdUseCase: GetChatIdUseCase(chatRepository),
              getChatStreamUseCase: GetChatStreamUseCase(chatRepository),
              getMessageHistoryUseCase: GetMessageHistoryUseCase(
                chatRepository,
              ),
              sendMessageUseCase: SendMessageUseCase(chatRepository),
              markMessagesAsReadUseCase: MarkMessagesAsReadUseCase(
                chatRepository,
              ),
            );
          },
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
            ),
            darkTheme: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFE3C72),
                brightness: Brightness.dark,
              ),
              textTheme: poppinsDark,
            ),
            home: AuthService().currentUser != null
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
