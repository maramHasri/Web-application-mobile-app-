import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_internet_application/l10n/app_localizations.dart';
import 'package:flutter_internet_application/view/Auth/signUP.dart';
import 'package:flutter_internet_application/core/providers/theme_provider.dart';
import 'package:flutter_internet_application/core/providers/language_provider.dart';
import 'package:flutter_internet_application/core/providers/app_providers.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("🔔 Background Notification: ${message.notification?.title}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    try {
      String? token = await messaging.getToken();
      debugPrint(" FCM Device Token: $token");
    } catch (e) {
      debugPrint(" Failed to get FCM token: $e");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(" Foreground Notification");

      if (message.notification != null) {
        _showPopup(
          message.notification!.title ?? "إشعار جديد",
          message.notification!.body ?? "",
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📨 App opened from background notification");

      if (message.data.containsKey("complaint_id")) {
        String complaintId = message.data["complaint_id"];
        debugPrint("Complaint ID: $complaintId");
        // TODO: Navigate to complaint details page
      }
    });

    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      debugPrint(" App opened from terminated notification");

      if (initialMessage.data.containsKey("complaint_id")) {
        String complaintId = initialMessage.data["complaint_id"];
        debugPrint("Complaint ID: $complaintId");
        // TODO: Navigate to complaint details page
      }
    }
  }

  void _showPopup(String title, String body) {
    if (navigatorKey.currentContext == null) return;

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
            child: const Text("close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
