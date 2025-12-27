import 'package:flutter/material.dart';
import 'package:flutter_internet_application/service/getComplain.dart';
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
    _complaintsFuture = _service.getUserComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
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
        backgroundColor: Colors.blue,
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
                ],
                onSelected: (String value) {
                  if (value == 'theme') {
                    themeProvider.toggleTheme();
                  } else if (value == 'language') {
                    languageProvider.toggleLanguage();
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
                                          color: Colors.blue.shade700,
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
