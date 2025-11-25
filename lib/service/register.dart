import 'package:dio/dio.dart';
import 'package:flutter_internet_application/model/userModel.dart';
import 'package:flutter_internet_application/service/tokenManage.dart';

abstract class AuthService {
  Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8000/api', // صحيح
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  Future<Map<String, dynamic>> register(User user); // تعديل
  Future<bool> login(User user);
  Future<bool> verifyOtp(String identifier, String code); // دالة OTP
}

class AuthServiceImpl extends AuthService {
  @override
  Future<Map<String, dynamic>> register(User user) async {
    try {
      print("==== SENDING REGISTER REQUEST ====");
      print("DATA SENT: ${user.toMap()}");

      Response response = await dio.post(
        "/auth/register",
        data: user.toMap(),
        options: Options(
          validateStatus: (status) => true, // منع رمي errors لأي status code
        ),
      );

      print("==== REGISTER RESPONSE ====");
      print("STATUS CODE: ${response.statusCode}");
      print("HEADERS: ${response.headers.map}");
      print("DATA: ${response.data}");

      // هنا بناءً على ال response المتوقع من السيرفر
      if (response.data != null &&
          response.data["success"] == true &&
          response.data["status_code"] == 200) {
        return {
          "success": true,
          "identifier":
              user.identifier, // السيرفر لم يرجع identifier، نستخدم المرسل
        };
      }

      return {"success": false};
    } catch (e) {
      print("==== REGISTER EXCEPTION ====");
      print(e);
      return {"success": false};
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
