import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_internet_application/core/constants/api_constants.dart';

class GetComplaintService {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  GetComplaintService({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
            ),
          );

  Future<List<Map<String, dynamic>>> getUserComplaints() async {
    try {
      String? userToken = await storage.read(key: 'userToken');

      if (userToken == null || userToken.isEmpty) {
        print("Error: User token is empty!");
        return [];
      }

      final response = await dio.get(
        "/user/complaints",
        options: Options(
          headers: {
            'Authorization': 'Bearer $userToken',
            'accept': 'application/json',
          },
        ),
      );

      print("Status code: ${response.statusCode}");
      print("Response body: ${response.data}");

      if (response.statusCode == 200 && response.data["success"] == true) {
        List complaints = response.data["data"] ?? [];
        return complaints
            .map<Map<String, dynamic>>((c) => c as Map<String, dynamic>)
            .toList();
      }

      print("Error fetching complaints: ${response.data["message"]}");
      return [];
    } catch (e) {
      print("Exception while fetching complaints: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getExtraInfoDetails({
    required String complaintId,
    required String infoId,
  }) async {
    try {
      String? userToken = await storage.read(key: 'userToken');

      if (userToken == null || userToken.isEmpty) {
        print("Error: User token is empty!");
        return null;
      }

      final response = await dio.get(
        "/user/complaints/$complaintId/extra_info/$infoId",
        options: Options(
          headers: {
            'Authorization': 'Bearer $userToken',
            'accept': 'application/json',
          },
          validateStatus: (_) => true,
        ),
      );

      print("📥 Get extra info response status: ${response.statusCode}");
      print("📥 Get extra info response body: ${response.data}");

      if (response.statusCode == 200 && response.data["success"] == true) {
        return response.data["data"] as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        print(
          "⚠️ Extra info endpoint not found (404). Backend might not have this endpoint.",
        );
        print(
          "💡 Solution: Backend should include 'key' field in /user/complaints response.",
        );
      }

      return null;
    } catch (e) {
      print("Exception while fetching extra info details: $e");
      return null;
    }
  }

  Future<bool> answerExtraInfo({
    required String complaintId,
    required String infoId,
    required String answer,
    File? file,
  }) async {
    try {
      String? userToken = await storage.read(key: 'userToken');

      if (userToken == null || userToken.isEmpty) {
        print("Error: User token is empty!");
        return false;
      }

      FormData formData = FormData.fromMap({"value": answer});
      if (file != null) {
        formData.files.add(
          MapEntry(
            "file",
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await dio.post(
        "/user/complaints/$complaintId/extra_info/$infoId/answer",
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $userToken',
            'accept': 'application/json',
          },
          validateStatus: (_) => true,
        ),
      );

      print("📤 Answer extra info response status: ${response.statusCode}");
      print("📤 Answer extra info response body: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Extra info answered successfully");
        return true;
      } else {
        print(
          "❌ Error answering extra info: ${response.statusCode} - ${response.data}",
        );
        return false;
      }
    } catch (e) {
      print("Exception while answering: $e");
      return false;
    }
  }
}
