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
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "شكاوي المستخدم",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
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

          final complaints = snapshot.data!.reversed.toList();

          return Padding(
            padding: const EdgeInsets.only(top: 50),
            child: ListView.builder(
              // reverse: true,
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Directionality(
                      textDirection:
                          TextDirection.rtl, // محاذاة النصوص للجهة اليمنى
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الصف الأول: الحالة والتاريخ
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'New',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                complaint['created_at'] ?? '---',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // الوصف
                          Text(
                            'الوصف: ${complaint['description'] ?? '---'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),

                          // الجهة
                          Text(
                            'الجهة: ${complaint['destination']?['name'] ?? '---'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),

                          // نوع الشكوى
                          Text(
                            'نوع الشكوى: ${complaint['complaint_type']?['name'] ?? '---'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
