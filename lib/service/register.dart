import 'package:dio/dio.dart';
import 'package:flutter_internet_application/model/userModel.dart';
import 'package:flutter_internet_application/service/tokenManage.dart';

abstract class AuthService {
  Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://192.168.1.4:8000/api",
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  Future<Map<String, dynamic>> register(User user);
  Future<bool> login(User user);
  Future<bool> verifyOtp(String identifier, String code);
}

class AuthServiceImpl extends AuthService {
  @override
  Future<Map<String, dynamic>> register(User user) async {
    try {
      Response response = await dio.post(
        "/auth/register",
        data: user.toMap(),
        options: Options(validateStatus: (status) => true),
      );

      final res = response.data ?? {};

      bool success = res["success"] == true && res["status_code"] == 200;

      return {
        "success": success,
        "message": res["message"]?.toString() ?? "",
        "errors": res["errors"] ?? {},
        "identifier": user.identifier,
        "data": res["data"] ?? {},
      };
    } catch (e, s) {
      print("REGISTER ERROR: $e");
      print("STACK: $s");
      return {"success": false, "message": "Unexpected error", "errors": {}};
    }
  }

  @override
  Future<bool> login(User user) async {
    try {
      Response response = await dio.post("/auth/login", data: user.toMap());

      if (response.statusCode == 200) {
        String token = response.data['token'];
        await TokenStorage.saveToken(token);
        return true;
      } else {
        print("Login Error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Login Exception: $e");
      return false;
    }
  }

  @override
  Future<bool> verifyOtp(String identifier, String code) async {
    try {
      Response response = await dio.post(
        "/auth/verify",
        data: {"identifier": identifier, "code": code},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("OTP Verify Failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("OTP Verify Exception: $e");
      return false;
    }
  }
}
