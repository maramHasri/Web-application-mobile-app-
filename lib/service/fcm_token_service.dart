import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_internet_application/core/constants/api_constants.dart';

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
               baseUrl: ApiConstants.baseUrl,
               connectTimeout: ApiConstants.connectTimeout,
               receiveTimeout: ApiConstants.receiveTimeout,
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
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint(
          "❌ Cannot send FCM token to backend: FCM token is null or empty",
        );
        return false;
      }

      final String? lastSentToken = await storage.read(key: _fcmTokenSentKey);
      if (lastSentToken == fcmToken) {
        debugPrint("ℹ️ FCM token already sent to backend (token unchanged)");
        return true;
      }

      debugPrint(
        "📤 Sending FCM token to backend: ${fcmToken.substring(0, 20)}...",
      );

      final response = await dio.post(
        "/user/fcm-token",
        data: {"device_token": fcmToken},
        options: Options(
          headers: {
            "Authorization": "Bearer $authToken",
            "accept": "application/json",
            "Content-Type": "application/json",
          },
          validateStatus: (_) => true,
        ),
      );

      debugPrint(
        "📥 Backend response: ${response.statusCode} - ${response.data}",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await storage.write(key: _fcmTokenSentKey, value: fcmToken);
        debugPrint("✅ FCM token sent to backend successfully and stored");
        return true;
      } else {
        debugPrint(
          "❌ Failed to send FCM token: ${response.statusCode} - ${response.data}",
        );
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error sending FCM token to backend: $e");
      debugPrint("Stack trace: $stackTrace");
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
