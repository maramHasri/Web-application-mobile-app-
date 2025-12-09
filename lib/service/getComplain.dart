// import 'package:dio/dio.dart';
// import 'package:flutter_internet_application/model/ComplaintResponse.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class GetComplaintService {
//   static final storage = FlutterSecureStorage();
//   static final Dio dio = Dio(
//     BaseOptions(
//       baseUrl: "http://192.168.1.6:8000",
//       headers: {"accept": "application/json"},
//     ),
//   );

//   /// جلب قائمة الشكاوي
//   static Future<List<Complaint>> getUserComplaints({String? token}) async {
//     try {
//       // إذا لم يُمر التوكن كوسيط، خذ التوكن من التخزين
//       token ??= await storage.read(key: "userToken");

//       if (token == null || token.isEmpty) {
//         print("Error: User token is empty!");
//         return [];
//       }

//       // إرسال الطلب
//       final res = await dio.get(
//         "/api/user/complaints",
//         options: Options(
//           headers: {
//             "Authorization": "Bearer $token",
//             "accept": "application/json",
//           },
//           validateStatus: (_) => true, // لالتقاط كل الأكواد حتى 500
//         ),
//       );

//       // طباعة الديباغ
//       print("Status code: ${res.statusCode}");
//       print("Response body: ${res.data}");

//       if (res.statusCode == 200) {
//         // تحويل الـ JSON إلى قائمة Complaint
//         final List<dynamic> data = res.data['data'];
//         return data.map((json) => Complaint.fromJson(json)).toList();
//       } else {
//         print("Server returned error: ${res.statusCode}");
//         return [];
//       }
//     } catch (e) {
//       print("Exception while fetching complaints: $e");
//       return [];
//     }
//   }
// }
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GetComplaintService {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  GetComplaintService({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: "http://192.168.1.106:8000/api",
              connectTimeout: Duration(seconds: 10),
              receiveTimeout: Duration(seconds: 10),
            ),
          );

  // جلب الشكاوى الخاصة بالمستخدم
  Future<List<Map<String, dynamic>>> getUserComplaints() async {
    try {
      // استرجاع التوكن المخزن
      String? userToken = await storage.read(key: 'userToken');

      if (userToken == null || userToken.isEmpty) {
        print("Error: User token is empty!");
        return [];
      }

      // إرسال الطلب مع التوكن في الهيدر
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
}
