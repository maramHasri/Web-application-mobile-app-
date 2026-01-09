import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_internet_application/service/getComplain.dart';
import 'package:flutter_internet_application/service/login.dart';
import 'package:flutter_internet_application/core/providers/app_providers.dart';
import 'package:flutter_internet_application/l10n/app_localizations.dart';
import 'package:flutter_internet_application/view/login.dart';
import 'package:flutter_internet_application/view/complain.dart';

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
  final LoginService _loginService = LoginService();
  String? _highlightComplaintId;
  String? _highlightExtraInfoId;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _highlightComplaintId = widget.data['highlight_complaint_id']?.toString();
    _highlightExtraInfoId = widget.data['highlight_extra_info_id']?.toString();
    _loadComplaints();

    // If we have highlight data, show the bottom sheet after data loads
    if (_highlightComplaintId != null && _highlightExtraInfoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadComplaintsAndShowExtraInfo();
      });
    }
  }

  void _loadComplaints() {
    setState(() {
      _complaintsFuture = _service.getUserComplaints();
    });
  }

  Future<void> _refreshComplaints() async {
    setState(() {
      _complaintsFuture = _service.getUserComplaints();
    });
    await _complaintsFuture;
  }

  Future<void> _loadComplaintsAndShowExtraInfo() async {
    final complaints = await _complaintsFuture;
    if (!mounted) return;

    for (final complaint in complaints) {
      if (complaint['id'].toString() == _highlightComplaintId) {
        final List extraInfoList = complaint['extra_info'] ?? [];
        for (final info in extraInfoList) {
          if (info['id'].toString() == _highlightExtraInfoId) {
            _showAnswerSheet(
              _highlightComplaintId!,
              _highlightExtraInfoId!,
              info['key']?.toString() ?? 'مطلوب معلومات إضافية',
            );
            // Clear highlight after showing
            setState(() {
              _highlightComplaintId = null;
              _highlightExtraInfoId = null;
            });
            return;
          }
        }
      }
    }
  }

  void _showAnswerSheet(String compId, String infoId, String title) {
    final controller = TextEditingController();
    File? selectedFile;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final textColor = Theme.of(context).textTheme.bodyLarge?.color;
          final hintColor = isDarkMode ? Colors.white70 : Colors.black54;
          final borderColor = isDarkMode
              ? Colors.blueGrey.shade700
              : Colors.grey.shade300;
          final focusedBorderColor = Theme.of(context).colorScheme.primary;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "مطلوب معلومات إضافية",
                            style: TextStyle(fontSize: 12, color: hintColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "الرجاء إدخال الإجابة:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "اكتب إجابتك هنا...",
                    hintStyle: TextStyle(color: hintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: focusedBorderColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ListTile(
                  leading: Icon(Icons.attach_file, color: textColor),
                  title: Text(
                    selectedFile == null
                        ? "إرفاق ملف (اختياري)"
                        : "تم اختيار الملف: ${selectedFile!.path.split(Platform.pathSeparator).last}",
                    style: TextStyle(color: textColor),
                  ),
                  trailing: selectedFile != null
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () async {
                    final res = await FilePicker.platform.pickFiles();
                    if (res != null) {
                      setModalState(
                        () => selectedFile = File(res.files.single.path!),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (controller.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("الرجاء إدخال الإجابة"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            final bool ok = await _service.answerExtraInfo(
                              complaintId: compId,
                              infoId: infoId,
                              answer: controller.text.trim(),
                              file: selectedFile,
                            );
                            if (!context.mounted) return;
                            if (ok) {
                              Navigator.pop(context);
                              _refreshComplaints();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("تم إرسال الإجابة بنجاح ✅"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("فشل إرسال الرد"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "إرسال الرد",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (_isLoggingOut) return;

    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).locale.languageCode == 'en'
              ? 'Logout'
              : 'تسجيل الخروج',
        ),
        content: Text(
          AppLocalizations.of(context).locale.languageCode == 'en'
              ? 'Are you sure you want to logout?'
              : 'هل أنت متأكد من تسجيل الخروج؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context).locale.languageCode == 'en'
                  ? 'Cancel'
                  : 'إلغاء',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context).locale.languageCode == 'en'
                  ? 'Logout'
                  : 'تسجيل الخروج',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      final bool success = await _loginService.logout();

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).locale.languageCode == 'en'
                  ? 'Logged out successfully'
                  : 'تم تسجيل الخروج بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).locale.languageCode == 'en'
                  ? 'Logged out (token cleared)'
                  : 'تم تسجيل الخروج (تم حذف الرمز)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Navigate to login page and clear navigation stack
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).locale.languageCode == 'en'
                ? 'Error during logout'
                : 'حدث خطأ أثناء تسجيل الخروج',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
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
              builder: (_) =>
                  ComplaintStepOne(data: {}, userToken: widget.userToken),
            ),
          ).then((_) {
            // Refresh complaints list when returning from creating a new complaint
            _loadComplaints();
          });
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
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context).locale.languageCode ==
                                  'en'
                              ? 'Logout'
                              : 'تسجيل الخروج',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
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
                  } else if (value == 'logout') {
                    _handleLogout(context);
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

          return RefreshIndicator(
            onRefresh: _refreshComplaints,
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  final List extraInfoList = complaint['extra_info'] ?? [];

                  // Check if there's a pending extra_info request
                  dynamic firstPendingInfo;
                  try {
                    firstPendingInfo = extraInfoList.firstWhere(
                      (info) =>
                          info['value'] == null ||
                          info['value'].toString().trim().isEmpty,
                    );
                  } catch (e) {
                    firstPendingInfo = null;
                  }
                  final bool hasPendingInfo = firstPendingInfo != null;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: hasPendingInfo
                        ? Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.5)
                        : Theme.of(context).cardColor,
                    elevation: hasPendingInfo ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: hasPendingInfo
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            )
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: hasPendingInfo && firstPendingInfo != null
                          ? () => _showAnswerSheet(
                              complaint['id'].toString(),
                              firstPendingInfo['id'].toString(),
                              firstPendingInfo['key']?.toString() ??
                                  'مطلوب معلومات إضافية',
                            )
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Directionality(
                          textDirection: textDirection,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (hasPendingInfo)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Builder(
                                          builder: (context) {
                                            final localizations =
                                                AppLocalizations.of(context);
                                            final status =
                                                complaint['status'] ?? '---';
                                            final translatedStatus =
                                                status != '---'
                                                ? localizations.translateStatus(
                                                    status,
                                                  )
                                                : status;
                                            return Row(
                                              children: [
                                                Text(
                                                  translatedStatus,
                                                  style: TextStyle(
                                                    color: hasPendingInfo
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : Colors.black54,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: const Color(
                                                    0xFF1F4E79,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
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
                              if (hasPendingInfo) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.pending_actions,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'مطلوب معلومات إضافية',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Builder(
                                builder: (context) {
                                  final localizations = AppLocalizations.of(
                                    context,
                                  );
                                  final destinationName =
                                      complaint['destination']?['name'] ??
                                      '---';
                                  final complaintTypeName =
                                      complaint['complaint_type']?['name'] ??
                                      '---';

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
