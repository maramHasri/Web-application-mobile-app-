import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FcmTokenService {
  final Dio dio;
  final FlutterSecureStorage storage;
  final FirebaseMessaging messaging;
  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmTokenSentKey = 'fcm_token_sent';

  FcmTokenService({
    Dio? dio,
    FlutterSecureStorage? storage,
    FirebaseMessaging? messaging,
  }) : dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: "http://192.168.1.104:8000/api",
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
             ),
           ),
       storage = storage ?? const FlutterSecureStorage(),
       messaging = messaging ?? FirebaseMessaging.instance;

  Future<String?> getFcmToken() async {
    try {
      final String? token = await messaging.getToken();
      if (token != null) {
        debugPrint("✅ FCM Token Retrieved: $token");
        await storage.write(key: _fcmTokenKey, value: token);
        return token;
      } else {
        debugPrint("❌ Failed to get FCM token: Token is null");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error getting FCM token: $e");
      return null;
    }
  }

  Future<bool> sendTokenToBackend(String? authToken) async {
    if (authToken == null || authToken.isEmpty) {
      debugPrint("⚠️ Cannot send FCM token: Auth token is missing");
      return false;
    }

    try {
      String? fcmToken = await getFcmToken();
      if (fcmToken == null) {
        debugPrint("❌ Cannot send FCM token to backend: FCM token is null");
        return false;
      }

      final String? lastSentToken = await storage.read(key: _fcmTokenSentKey);
      if (lastSentToken == fcmToken) {
        debugPrint("ℹ️ FCM token already sent to backend");
        return true;
      }

      final response = await dio.post(
        "/user/fcm-token",
        data: {"device_token": fcmToken},
        options: Options(
          headers: {
            "Authorization": "Bearer $authToken",
            "accept": "application/json",
          },
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await storage.write(key: _fcmTokenSentKey, value: fcmToken);
        debugPrint("✅ FCM token sent to backend successfully");
        return true;
      } else {
        debugPrint(
          "❌ Failed to send FCM token: ${response.statusCode} - ${response.data}",
        );
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error sending FCM token to backend: $e");
      return false;
    }
  }

  Future<void> setupTokenRefreshListener(String? authToken) async {
    messaging.onTokenRefresh.listen((String newToken) async {
      debugPrint("🔄 FCM Token refreshed: $newToken");
      await storage.write(key: _fcmTokenKey, value: newToken);
      await storage.delete(key: _fcmTokenSentKey);
      if (authToken != null && authToken.isNotEmpty) {
        await sendTokenToBackend(authToken);
      }
    });
  }

  Future<void> clearToken() async {
    await storage.delete(key: _fcmTokenKey);
    await storage.delete(key: _fcmTokenSentKey);
    await messaging.deleteToken();
    debugPrint("🗑️ FCM token cleared");
  }
}
