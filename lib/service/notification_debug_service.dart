import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_internet_application/service/notification_service.dart';

class NotificationDebugService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> printDebugInfo() async {
    debugPrint("═══════════════════════════════════════");
    debugPrint("🔍 FCM NOTIFICATION DEBUG INFO");
    debugPrint("═══════════════════════════════════════");

    try {
      final String? fcmToken = await _messaging.getToken();
      debugPrint("📱 FCM Token: ${fcmToken ?? 'NULL'}");
      debugPrint("📱 FCM Token Length: ${fcmToken?.length ?? 0}");

      final String? savedToken = await _storage.read(key: 'fcm_token');
      debugPrint("💾 Saved Token: ${savedToken ?? 'NULL'}");
      debugPrint("💾 Tokens Match: ${fcmToken == savedToken}");

      final String? tokenSent = await _storage.read(key: 'fcm_token_sent');
      debugPrint("📤 Token Sent to Backend: ${tokenSent ?? 'NULL'}");
      debugPrint("📤 Token Sent Matches Current: ${fcmToken == tokenSent}");

      final String? userToken = await _storage.read(key: 'userToken');
      debugPrint(
        "🔑 User Auth Token: ${userToken != null ? 'EXISTS (${userToken.length} chars)' : 'NULL'}",
      );

      final NotificationSettings settings = await _messaging
          .getNotificationSettings();
      debugPrint("🔔 Notification Settings:");
      debugPrint("   - Authorization Status: ${settings.authorizationStatus}");
      debugPrint("   - Alert: ${settings.alert}");
      debugPrint("   - Badge: ${settings.badge}");
      debugPrint("   - Sound: ${settings.sound}");

      debugPrint("═══════════════════════════════════════");
    } catch (e) {
      debugPrint("❌ Error getting debug info: $e");
    }
  }

  static Future<void> testLocalNotification() async {
    debugPrint("🧪 Testing local notification...");
    await NotificationService.showLocalNotification(
      id: 999,
      title: "Test Notification",
      body:
          "This is a test notification to verify the notification system is working",
      payload: "test",
    );
    debugPrint("✅ Test notification sent");
  }

  static Future<String?> getCurrentFcmToken() async {
    try {
      final String? token = await _messaging.getToken();
      return token;
    } catch (e) {
      debugPrint("❌ Error getting FCM token: $e");
      return null;
    }
  }

  static Future<bool> checkNotificationPermissions() async {
    try {
      final NotificationSettings settings = await _messaging
          .getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint("❌ Error checking permissions: $e");
      return false;
    }
  }
}
