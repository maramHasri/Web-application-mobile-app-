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
