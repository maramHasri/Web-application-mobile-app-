import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_internet_application/main.dart';
import 'package:flutter_internet_application/view/allComplains.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint("ℹ️ NotificationService already initialized");
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _isInitialized = true;
    debugPrint("✅ NotificationService initialized");
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint("📱 Notification tapped: ${response.payload}");
    if (response.payload != null) {
      handleNotificationNavigation(response.payload!);
    }
  }

  static Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        "📱 iOS Notification Permission: ${settings.authorizationStatus}",
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint("✅ iOS notifications authorized");
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint("⚠️ iOS notifications provisionally authorized");
      } else {
        debugPrint("❌ iOS notifications denied");
      }
    } else if (Platform.isAndroid) {
      final bool? granted = await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      debugPrint("📱 Android Notification Permission: $granted");
    }
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);

    debugPrint("📬 Local notification shown: $title - $body");
  }

  static Future<void> handleForegroundMessage(RemoteMessage message) async {
    debugPrint("📨 Foreground notification received");
    debugPrint("Title: ${message.notification?.title}");
    debugPrint("Body: ${message.notification?.body}");
    debugPrint("Data: ${message.data}");

    final String title = message.notification?.title ?? "تم تحديث حالة الشكوى";
    final String body =
        message.notification?.body ?? "تم تحديث حالة الشكوى الخاصة بك";

    // Extract complaint ID from data payload
    final String? complaintId =
        message.data['complaint_id']?.toString() ??
        message.data['order_id']?.toString();

    // Create payload with all relevant data
    final String payload = complaintId ?? '';

    await showLocalNotification(
      id: complaintId != null ? int.tryParse(complaintId) ?? 0 : 0,
      title: title,
      body: body,
      payload: payload,
    );
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint("🔔 Background notification received");
    debugPrint("Title: ${message.notification?.title}");
    debugPrint("Body: ${message.notification?.body}");
    debugPrint("Data: ${message.data}");

    // Background notifications are automatically displayed by the system
    // This handler is mainly for logging and potential data processing
    final String? complaintId = message.data['complaint_id']?.toString();
    final String? notificationType = message.data['type']?.toString();

    if (notificationType == 'complaint_status_update' && complaintId != null) {
      debugPrint(
        "📋 Complaint status update: ID=$complaintId, Old=${message.data['old_status']}, New=${message.data['new_status']}",
      );
    }
  }

  static void handleNotificationNavigation(String payload) {
    debugPrint("🧭 Navigating from notification: $payload");

    if (navigatorKey.currentContext == null) {
      debugPrint("⚠️ Navigator context is null, cannot navigate");
      return;
    }

    final BuildContext context = navigatorKey.currentContext!;

    // If payload contains complaint ID, navigate to complaints page
    // The complaints page will show the updated complaint
    if (payload.isNotEmpty) {
      debugPrint("📋 Navigating to complaint: $payload");
    }

    _navigateToComplaintsPage(context);
  }

  static void _navigateToComplaintsPage(BuildContext context) async {
    debugPrint("🧭 Navigating to complaints page");
    const storage = FlutterSecureStorage();
    final String? userToken = await storage.read(key: 'userToken');

    if (userToken != null && userToken.isNotEmpty) {
      // Use pushAndRemoveUntil to clear navigation stack and navigate to complaints
      // The ComplaintsPage will automatically refresh data in initState
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ComplaintsPage(data: {}, userToken: userToken),
        ),
        (route) => false,
      );
    } else {
      debugPrint("⚠️ User token not found, cannot navigate to complaints");
    }
  }

  static Future<void> setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📱 App opened from background notification");
      debugPrint("Notification data: ${message.data}");

      final String? complaintId =
          message.data['complaint_id']?.toString() ??
          message.data['order_id']?.toString();

      if (navigatorKey.currentContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationNavigation(complaintId ?? '');
        });
      }
    });

    final RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      debugPrint("📱 App opened from terminated notification");
      debugPrint("Notification data: ${initialMessage.data}");

      final String? complaintId =
          initialMessage.data['complaint_id']?.toString() ??
          initialMessage.data['order_id']?.toString();

      if (navigatorKey.currentContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationNavigation(complaintId ?? '');
        });
      }
    }
  }
}
