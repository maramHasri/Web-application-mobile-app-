import 'package:flutter/material.dart';
import 'package:flutter_internet_application/service/getComplain.dart';
import 'package:flutter_internet_application/service/notification_debug_service.dart';
import 'package:flutter_internet_application/view/complain.dart';
import 'package:flutter_internet_application/core/providers/app_providers.dart';
import 'package:flutter_internet_application/l10n/app_localizations.dart';

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({
    super.key,
    required this.data,
    required this.userToken,
  });
  final Map<String, dynamic> data;
  final String userToken;

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late Future<List<Map<String, dynamic>>> _complaintsFuture;
  final GetComplaintService _service = GetComplaintService();

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  void _loadComplaints() {
    setState(() {
      _complaintsFuture = _service.getUserComplaints();
    });
  }

  Future<void> _showDebugDialog(BuildContext context) async {
    await NotificationDebugService.printDebugInfo();
    final String? fcmToken =
        await NotificationDebugService.getCurrentFcmToken();
    final bool hasPermission =
        await NotificationDebugService.checkNotificationPermissions();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FCM Token: ${fcmToken ?? "NULL"}'),
              const SizedBox(height: 8),
              Text('Token Length: ${fcmToken?.length ?? 0}'),
              const SizedBox(height: 8),
              Text('Has Permission: ${hasPermission ? "YES" : "NO"}'),
              const SizedBox(height: 16),
              const Text(
                'Check console logs for full debug info.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationDebugService.testLocalNotification();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Test notification sent! Check your notifications.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Test Notification'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1F4E79),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintStepOne(
                data: widget.data,
                userToken: widget.userToken,
              ),
            ),
          );
        },
      ),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1F4E79),
        title: Text(AppLocalizations.of(context).usersComplaints),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) {
              final appProviders = AppProviders.of(context);
              if (appProviders == null) {
                return const SizedBox.shrink();
              }
              final themeProvider = appProviders.themeProvider;
              final languageProvider = appProviders.languageProvider;
              final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
              final currentLanguage = languageProvider.locale.languageCode;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: Theme.of(context).scaffoldBackgroundColor,
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isDarkMode ? 'light mood' : 'dark mood',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'language',
                    child: Row(
                      children: [
                        const Icon(Icons.language),
                        const SizedBox(width: 12),
                        Text(
                          currentLanguage == 'ar'
                              ? 'Change to English'
                              : 'التبديل إلى العربية',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'debug',
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report),
                        const SizedBox(width: 12),
                        Text(
                          'Debug Notifications',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (String value) {
                  if (value == 'theme') {
                    themeProvider.toggleTheme();
                  } else if (value == 'language') {
                    languageProvider.toggleLanguage();
                  } else if (value == 'debug') {
                    _showDebugDialog(context);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          final appProviders = AppProviders.of(context);
          final currentLanguage =
              appProviders?.languageProvider.locale.languageCode ?? 'ar';
          final textDirection = currentLanguage == 'en'
              ? TextDirection.ltr
              : TextDirection.rtl;

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
                      textDirection: textDirection,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                child: Builder(
                                  builder: (context) {
                                    final localizations = AppLocalizations.of(
                                      context,
                                    );
                                    final status = complaint['status'] ?? '---';
                                    final translatedStatus = status != '---'
                                        ? localizations.translateStatus(status)
                                        : status;
                                    return Row(
                                      children: [
                                        Text(
                                          translatedStatus,
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.check,
                                          size: 16,
                                          color: const Color(0xFF1F4E79),
                                        ),
                                      ],
                                    );
                                  },
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

                          Builder(
                            builder: (context) {
                              final localizations = AppLocalizations.of(
                                context,
                              );
                              final destinationName =
                                  complaint['destination']?['name'] ?? '---';
                              final complaintTypeName =
                                  complaint['complaint_type']?['name'] ?? '---';

                              final translatedDestination =
                                  destinationName != '---'
                                  ? localizations.translateDestination(
                                      destinationName,
                                    )
                                  : destinationName;
                              final translatedComplaintType =
                                  complaintTypeName != '---'
                                  ? localizations.translateComplaintType(
                                      complaintTypeName,
                                    )
                                  : complaintTypeName;

                              final isEnglish =
                                  localizations.locale.languageCode == 'en';
                              final descriptionLabel = isEnglish
                                  ? 'Description: '
                                  : 'الوصف: ';
                              final destinationLabel = isEnglish
                                  ? 'Destination: '
                                  : 'الجهة: ';
                              final complaintTypeLabel = isEnglish
                                  ? 'Complaint Type: '
                                  : 'نوع الشكوى: ';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$descriptionLabel${complaint['description'] ?? '---'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$destinationLabel$translatedDestination',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$complaintTypeLabel$translatedComplaintType',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              );
                            },
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
