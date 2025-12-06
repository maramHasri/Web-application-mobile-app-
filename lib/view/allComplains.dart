// import 'package:flutter/material.dart';
// import 'package:flutter_internet_application/model/ComplaintResponse.dart';
// import 'package:flutter_internet_application/service/getComplain.dart';

// class ComplaintsPage extends StatefulWidget {
//   final String userToken;

//   const ComplaintsPage({super.key, required this.userToken});

//   @override
//   State<ComplaintsPage> createState() => _ComplaintsPageState();
// }

// class _ComplaintsPageState extends State<ComplaintsPage> {
//   late Future<List<Complaint>> _complaintsFuture;
//   // final GetComplaintService _service = GetComplaintService();

//   @override
//   void initState() {
//     super.initState();
//     _complaintsFuture = GetComplaintService.getUserComplaints(
//       token: widget.userToken,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('شكاوي المستخدم')),
//       body: FutureBuilder<List<Complaint>>(
//         future: _complaintsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             // أثناء التحميل
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             // في حال وجود خطأ
//             return Center(
//               child: Text(
//                 'حدث خطأ: ${snapshot.error}',
//                 style: const TextStyle(color: Colors.red),
//               ),
//             );
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             // في حال عدم وجود بيانات
//             return const Center(child: Text('لا توجد شكاوى حالياً'));
//           }

//           // عرض الشكاوى
//           final complaints = snapshot.data!;

//           return ListView.builder(
//             itemCount: complaints.length,
//             itemBuilder: (context, index) {
//               final complaint = complaints[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 child: ListTile(
//                   title: Text(
//                     complaint.identifier,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('الوصف: ${complaint.description}'),
//                       Text('الحالة: ${complaint.status}'),
//                       Text('الوجهة: ${complaint.destinationName}'),
//                       Text('نوع الشكوى: ${complaint.complaintTypeName}'),
//                       Text('العنوان: ${complaint.address}'),
//                       Text('تاريخ الإنشاء: ${complaint.createdAt}'),
//                     ],
//                   ),
//                   isThreeLine: true,
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_internet_application/service/getComplain.dart';

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({super.key});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late Future<List<Map<String, dynamic>>> _complaintsFuture;
  final GetComplaintService _service = GetComplaintService();

  @override
  void initState() {
    super.initState();
    _complaintsFuture = _service.getUserComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شكاوي المستخدم')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد شكاوى حالياً'));
          }

          final complaints = snapshot.data!;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final user = complaint['user'] ?? {};
              final complaintType = complaint['complaint_type'] ?? {};
              final destination = complaint['destination'] ?? {};

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    complaint['identifier'] ?? '---',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الوصف: ${complaint['description'] ?? '---'}'),
                      Text('الحالة: ${complaint['status'] ?? '---'}'),
                      Text('الوجهة: ${destination['name'] ?? '---'}'),
                      Text('نوع الشكوى: ${complaintType['name'] ?? '---'}'),
                      Text('العنوان: ${complaint['address'] ?? '---'}'),
                      Text(
                        'تاريخ الإنشاء: ${complaint['created_at'] ?? '---'}',
                      ),
                      Text('مقدم الشكوى: ${user['name'] ?? '---'}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
