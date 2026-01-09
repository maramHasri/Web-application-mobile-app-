import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_internet_application/l10n/app_localizations.dart';
import 'package:flutter_internet_application/view/Auth/signUP.dart';
import 'package:flutter_internet_application/core/providers/theme_provider.dart';
import 'package:flutter_internet_application/core/providers/language_provider.dart';
import 'package:flutter_internet_application/core/providers/app_providers.dart';
import 'package:flutter_internet_application/service/notification_service.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.handleBackgroundMessage(message);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint("⚠️ Firebase initialization timeout");
        throw TimeoutException("Firebase init timeout");
      },
    );
    debugPrint("✅ Firebase initialized");
  } catch (e) {
    debugPrint("❌ Firebase initialization error: $e");
  }

  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("❌ Background message handler error: $e");
  }

  // Initialize notifications in background (non-blocking)
  NotificationService.initialize()
      .then((_) {
        debugPrint("✅ NotificationService initialized");
        NotificationService.requestPermissions()
            .then((_) {
              debugPrint("✅ Permissions requested");
            })
            .catchError((e) {
              debugPrint("❌ Permission request error: $e");
            });
        NotificationService.setupMessageHandlers()
            .then((_) {
              debugPrint("✅ Message handlers setup");
            })
            .catchError((e) {
              debugPrint("❌ Message handlers setup error: $e");
            });

        // Get and print FCM token for debugging
        FirebaseMessaging.instance
            .getToken()
            .then((token) {
              if (token != null) {
                debugPrint("📱 FCM Token: $token");
                debugPrint("📱 FCM Token Length: ${token.length}");
              } else {
                debugPrint("⚠️ FCM Token is NULL");
              }
            })
            .catchError((e) {
              debugPrint("❌ Error getting FCM token: $e");
            });
      })
      .catchError((e) {
        debugPrint("❌ NotificationService initialization error: $e");
      });

  // FCM token will be sent to backend after user login (see login.dart)
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final LanguageProvider _languageProvider = LanguageProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChanged);
    _languageProvider.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    _languageProvider.removeListener(_onLanguageChanged);
    _themeProvider.dispose();
    _languageProvider.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _languageProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          // Primary colors
          primary: Color(0xFF1F4E79),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF2E5F8F),
          onPrimaryContainer: Colors.white,

          // Secondary colors
          secondary: Color(0xFF4A90E2),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFF6BA3E8),
          onSecondaryContainer: Colors.white,

          // Tertiary colors
          tertiary: Color(0xFF7B9EC8),
          onTertiary: Colors.white,

          // Error colors
          error: Color(0xFFD32F2F),
          onError: Colors.white,
          errorContainer: Color(0xFFFFCDD2),
          onErrorContainer: Color(0xFFB71C1C),

          // Background colors
          background: Color(0xFFF5F5F5),
          onBackground: Color(0xFF1A1A1A),
          surface: Colors.white,
          onSurface: Color(0xFF1A1A1A),

          // Surface variant (for cards, etc.)
          surfaceVariant: Color(0xFFE8E8E8),
          onSurfaceVariant: Color(0xFF424242),

          // Outline colors
          outline: Color(0xFFBDBDBD),
          outlineVariant: Color(0xFFE0E0E0),

          // Shadow
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),

          // Inverse colors
          inverseSurface: Color(0xFF1A1A1A),
          onInverseSurface: Colors.white,
          inversePrimary: Color(0xFF6BA3E8),
        ),
        useMaterial3: true,
        // Card theme customization
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          // Primary colors
          primary: Color(0xFF6BA3E8),
          onPrimary: Color(0xFF0A1F3A),
          primaryContainer: Color(0xFF2E5F8F),
          onPrimaryContainer: Color(0xFFE3F2FD),

          // Secondary colors
          secondary: Color(0xFF90C5F7),
          onSecondary: Color(0xFF0A1F3A),
          secondaryContainer: Color(0xFF4A90E2),
          onSecondaryContainer: Color(0xFFE3F2FD),

          // Tertiary colors
          tertiary: Color(0xFF9DB5D1),
          onTertiary: Color(0xFF0A1F3A),

          // Error colors
          error: Color(0xFFEF5350),
          onError: Color(0xFF1A0000),
          errorContainer: Color(0xFFB71C1C),
          onErrorContainer: Color(0xFFFFCDD2),

          // Background colors
          background: Color(0xFF121212),
          onBackground: Color(0xFFE0E0E0),
          surface: Color(0xFF1E1E1E),
          onSurface: Color(0xFFE0E0E0),

          // Surface variant (for cards, etc.) - darker for dark mode
          surfaceVariant: Color(0xFF2C2C2C),
          onSurfaceVariant: Color(0xFFBDBDBD),

          // Outline colors
          outline: Color(0xFF616161),
          outlineVariant: Color(0xFF424242),

          // Shadow
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),

          // Inverse colors
          inverseSurface: Color(0xFFE0E0E0),
          onInverseSurface: Color(0xFF1A1A1A),
          inversePrimary: Color(0xFF1F4E79),
        ),
        useMaterial3: true,
        // Card theme customization for dark mode
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E1E),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      themeMode: _themeProvider.themeMode,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return AppProviders(
          themeProvider: _themeProvider,
          languageProvider: _languageProvider,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const NotificationHandler(child: SignUpOrEnterAsGuest()),
    );
  }
}

class NotificationHandler extends StatefulWidget {
  final Widget child;

  const NotificationHandler({required this.child, super.key});

  @override
  State<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
