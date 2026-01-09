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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4E79),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4E79),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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
