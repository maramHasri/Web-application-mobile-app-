import 'dart:convert';
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

    final String? notificationType = message.data['type']?.toString();
    debugPrint("🔍 Notification type: $notificationType");

    String title;
    String body;

    if (notificationType == 'extra_info_request') {
      debugPrint("✅ Detected extra_info_request notification");
      title = message.notification?.title ?? "مطلوب معلومات إضافية";
      body =
          message.notification?.body ??
          "الرجاء تقديم المعلومات المطلوبة لمتابعة معالجة شكواك.";
      debugPrint("📝 Using title: $title");
      debugPrint("📝 Using body: $body");
    } else {
      title = message.notification?.title ?? "تم تحديث حالة الشكوى";
      body = message.notification?.body ?? "تم تحديث حالة الشكوى الخاصة بك";
    }

    // Extract complaint ID and extra_info_id from data payload
    final String? complaintId =
        message.data['complaint_id']?.toString() ??
        message.data['order_id']?.toString();
    final String? extraInfoId = message.data['extra_info_id']?.toString();

    debugPrint("🔍 Complaint ID: $complaintId");
    debugPrint("🔍 Extra Info ID: $extraInfoId");

    // Create payload with all relevant data (JSON format for parsing)
    final String payload =
        extraInfoId != null && notificationType == 'extra_info_request'
        ? jsonEncode({
            'complaint_id': complaintId,
            'extra_info_id': extraInfoId,
            'type': notificationType,
          })
        : complaintId ?? '';

    debugPrint("📦 Payload: $payload");

    if (notificationType == 'extra_info_request' && extraInfoId == null) {
      debugPrint(
        "⚠️ WARNING: extra_info_request notification received but extra_info_id is missing!",
      );
      debugPrint(
        "⚠️ This notification will not work properly. Backend must include 'extra_info_id' in data payload.",
      );
    }

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
    final String? extraInfoId = message.data['extra_info_id']?.toString();

    if (notificationType == 'complaint_status_update' && complaintId != null) {
      debugPrint(
        "📋 Complaint status update: ID=$complaintId, Old=${message.data['old_status']}, New=${message.data['new_status']}",
      );
    } else if (notificationType == 'extra_info_request' &&
        complaintId != null &&
        extraInfoId != null) {
      debugPrint(
        "📋 Extra info request: Complaint ID=$complaintId, Extra Info ID=$extraInfoId",
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

    // Try to parse JSON payload for extra_info_request
    String? complaintId;
    String? extraInfoId;
    String? notificationType;

    try {
      if (payload.startsWith('{')) {
        // JSON payload
        final Map<String, dynamic> data = jsonDecode(payload);
        complaintId = data['complaint_id']?.toString();
        extraInfoId = data['extra_info_id']?.toString();
        notificationType = data['type']?.toString();
      } else {
        // Simple complaint ID payload
        complaintId = payload;
      }
    } catch (e) {
      debugPrint("⚠️ Error parsing payload: $e");
      complaintId = payload;
    }

    if (notificationType == 'extra_info_request' &&
        complaintId != null &&
        extraInfoId != null) {
      debugPrint(
        "📋 Navigating to complaint with extra info: Complaint ID=$complaintId, Extra Info ID=$extraInfoId",
      );
      _navigateToComplaintsPageWithExtraInfo(context, complaintId, extraInfoId);
    } else if (payload.isNotEmpty) {
      debugPrint("📋 Navigating to complaint: $payload");
      _navigateToComplaintsPage(context);
    } else {
      _navigateToComplaintsPage(context);
    }
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

  static void _navigateToComplaintsPageWithExtraInfo(
    BuildContext context,
    String complaintId,
    String extraInfoId,
  ) async {
    debugPrint("🧭 Navigating to complaints page with extra info");
    const storage = FlutterSecureStorage();
    final String? userToken = await storage.read(key: 'userToken');

    if (userToken != null && userToken.isNotEmpty) {
      // Navigate to complaints page with extra info parameters
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ComplaintsPage(
            data: {
              'highlight_complaint_id': complaintId,
              'highlight_extra_info_id': extraInfoId,
            },
            userToken: userToken,
          ),
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
      final String? extraInfoId = message.data['extra_info_id']?.toString();
      final String? notificationType = message.data['type']?.toString();

      String payload;
      if (notificationType == 'extra_info_request' &&
          complaintId != null &&
          extraInfoId != null) {
        payload = jsonEncode({
          'complaint_id': complaintId,
          'extra_info_id': extraInfoId,
          'type': notificationType,
        });
      } else {
        payload = complaintId ?? '';
      }

      if (navigatorKey.currentContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationNavigation(payload);
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
      final String? extraInfoId = initialMessage.data['extra_info_id']
          ?.toString();
      final String? notificationType = initialMessage.data['type']?.toString();

      String payload;
      if (notificationType == 'extra_info_request' &&
          complaintId != null &&
          extraInfoId != null) {
        payload = jsonEncode({
          'complaint_id': complaintId,
          'extra_info_id': extraInfoId,
          'type': notificationType,
        });
      } else {
        payload = complaintId ?? '';
      }

      if (navigatorKey.currentContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationNavigation(payload);
        });
      }
    }
  }
}
