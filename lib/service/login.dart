import 'package:dio/dio.dart';
import 'package:flutter_internet_application/service/tokenManage.dart';

class LoginService {
  final Dio dio;

  LoginService({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: "http://192.168.1.6:8000/api",
              connectTimeout: Duration(seconds: 10),
              receiveTimeout: Duration(seconds: 10),
            ),
          );
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required String deviceToken,
  }) async {
    try {
      final response = await dio.post(
        "/auth/login",
        data: {
          "identifier": identifier,
          "password": password,
          "device_token": deviceToken,
        },
        options: Options(validateStatus: (_) => true),
      );

      final res = response.data ?? {};

      print("LOGIN RESPONSE = ${response.data}"); // ← مهم جداً

      if (response.statusCode == 200 && res["success"] == true) {
        String token = res["data"]["token"] ?? "";

        print("TOKEN FROM BACKEND = $token"); // ← تأكد أن التوكن وصل

        if (token.isNotEmpty) {
          await TokenStorage.saveToken(token);

          // تأكد من أنه فعلاً تم حفظه:
          String? saved = await TokenStorage.getToken();
          print("TOKEN SAVED IN STORAGE = $saved"); // ← أهم print في حياتك
        } else {
          return {"success": false, "message": "Token not received"};
        }

        return {
          "success": true,
          "message": res["message"] ?? "Login successful",
          "data": res["data"],
        };
      }

      return {
        "success": false,
        "message": res["message"] ?? "Login failed",
        "errors": res["errors"] ?? {},
      };
    } catch (e, s) {
      print("LOGIN ERROR: $e");
      print("STACK: $s");
      return {"success": false, "message": "Unexpected error"};
    }
  }
}
