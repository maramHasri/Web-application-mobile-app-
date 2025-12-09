import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class sendComplainService {
  static final storage = FlutterSecureStorage();
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://192.168.1.106:8000",
      headers: {"accept": "application/json"},
    ),
  );

  static Future<bool> sendComplaint({
    required Map data,
    required List<File> images,
    required List<File> documents,
    required String token, // استخدم هذا
  }) async {
    try {
      final formData = FormData();

      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      for (final img in images) {
        formData.files.add(
          MapEntry("images[]", await MultipartFile.fromFile(img.path)),
        );
      }

      for (final doc in documents) {
        formData.files.add(
          MapEntry("documents[]", await MultipartFile.fromFile(doc.path)),
        );
      }
      final token = await storage.read(key: "userToken");

      final res = await dio.post(
        "/api/user/complaints",
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
          headers: {
            "Authorization": "Bearer $token",
            "accept": "application/json",
          },
          validateStatus: (_) => true,
        ),
      );

      // Debug information
      print("Request headers: ${res.requestOptions.headers}");
      print("Status code: ${res.statusCode}");
      print("Response body: ${res.data}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      print("Error response: ${res.data}");
      return false;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }
}
