import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_internet_application/core/constants/api_constants.dart';
import 'package:flutter_internet_application/service/tokenManage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginService {
  final Dio dio;

  LoginService({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required String deviceToken,
  }) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("FCM DEVICE TOKEN = $fcmToken");

      if (fcmToken == null) {
        return {"success": false, "message": "Cannot get device token"};
      }

      final response = await dio.post(
        "/auth/login",
        data: {
          "identifier": identifier,
          "password": password,
          "device_token": fcmToken,
        },
        options: Options(validateStatus: (_) => true),
      );

      final res = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      print("LOGIN RESPONSE = ${response.data}");

      if (response.statusCode == 200 && res["success"] == true) {
        final data = res["data"] is Map<String, dynamic>
            ? res["data"] as Map<String, dynamic>
            : <String, dynamic>{};
        String token = data["token"]?.toString() ?? "";

        print("TOKEN FROM BACKEND = $token");

        if (token.isNotEmpty) {
          await TokenStorage.saveToken(token);

          String? saved = await TokenStorage.getToken();
          print("TOKEN SAVED IN STORAGE = $saved");
        } else {
          return {"success": false, "message": "Token not received"};
        }

        String message = res["message"] is String
            ? res["message"] as String
            : (res["message"] is List
                  ? (res["message"] as List).isNotEmpty
                        ? (res["message"] as List).first.toString()
                        : "Login successful"
                  : "Login successful");

        return {"success": true, "message": message, "data": data};
      }

      String errorMessage = res["message"] is String
          ? res["message"] as String
          : (res["message"] is List
                ? (res["message"] as List).isNotEmpty
                      ? (res["message"] as List).first.toString()
                      : "Login failed"
                : "Login failed");

      final errors = res["errors"] is Map<String, dynamic>
          ? res["errors"] as Map<String, dynamic>
          : <String, dynamic>{};

      return {"success": false, "message": errorMessage, "errors": errors};
    } catch (e, s) {
      print("LOGIN ERROR: $e");
      print("STACK: $s");
      return {"success": false, "message": "Unexpected error"};
    }
  }

  Future<bool> logout() async {
    try {
      final String? userToken = await TokenStorage.getToken();

      if (userToken == null || userToken.isEmpty) {
        debugPrint("⚠️ No user token found for logout");
        // Clear storage anyway
        await TokenStorage.clearToken();
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'userToken');
        return false;
      }

      final response = await dio.post(
        "/auth/logout",
        options: Options(
          headers: {
            'Authorization': 'Bearer $userToken',
            'Accept': 'application/json',
          },
          validateStatus: (_) => true,
        ),
      );

      debugPrint("Logout response status: ${response.statusCode}");
      debugPrint("Logout response body: ${response.data}");

      // Clear token regardless of response status
      await TokenStorage.clearToken();
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'userToken');
      debugPrint("✅ User token cleared from storage");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("❌ Logout error: $e");
      // Clear token even if API call fails
      await TokenStorage.clearToken();
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'userToken');
      return false;
    }
  }
}
