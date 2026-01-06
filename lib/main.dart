import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_internet_application/l10n/app_localizations.dart';
import 'package:flutter_internet_application/service/fcm_token_service.dart';
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await NotificationService.setupMessageHandlers();
  await FcmTokenService().sendTokenToBackend(
    await FirebaseMessaging.instance.getToken(),
  );
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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
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
