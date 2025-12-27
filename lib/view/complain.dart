import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_internet_application/core/widget/app_button.dart';
import 'package:flutter_internet_application/core/widget/app_textfield.dart';
import 'package:flutter_internet_application/view/allComplains.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_internet_application/l10n/app_localizations.dart';

import '../service/complainService.dart';

class ComplaintStepOne extends StatefulWidget {
  final String userToken;
  final Map<String, dynamic> data;

  const ComplaintStepOne({
    Key? key,
    required this.userToken,
    required this.data,
  }) : super(key: key);

  @override
  State<ComplaintStepOne> createState() => _ComplaintStepOneState();
}

class _ComplaintStepOneState extends State<ComplaintStepOne> {
  final TextEditingController complaintTypeController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool autoLocation = false;
  bool fetchingLocation = false;
  double? latitude;
  double? longitude;

  final List<Map<String, dynamic>> complaintTypes = [
    {"id": "1", "name": "Service Delay"},
    {"id": "2", "name": "Misconduct"},
    {"id": "3", "name": "Billing Issue"},
    {"id": "4", "name": "Technical Problem"},
    {"id": "5", "name": "Other"},
  ];

  final List<Map<String, dynamic>> destinations = [
    {"id": "1", "name": "Ministry of Energy"},
    {"id": "2", "name": "Ministry of Interior"},
  ];

  Future<void> getCurrentLocation() async {
    setState(() => fetchingLocation = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى تفعيل خدمة الموقع على الجهاز")),
      );
      setState(() => fetchingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم رفض إذن الوصول إلى الموقع")),
        );
        setState(() => fetchingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "تم رفض إذن الموقع بشكل دائم، يرجى تغييره من إعدادات الجهاز",
          ),
        ),
      );
      setState(() => fetchingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude = position.latitude;
      longitude = position.longitude;
      widget.data['lat'] = latitude.toString();
      widget.data['lng'] = longitude.toString();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فشل الحصول على الموقع")));
    }

    setState(() => fetchingLocation = false);
  }

  void submitData() {
    widget.data['complaint_type_id'] = complaintTypeController.text.isNotEmpty
        ? complaintTypeController.text
        : null;
    widget.data['destination_id'] = destinationController.text.isNotEmpty
        ? destinationController.text
        : null;
    widget.data['address'] = addressController.text.isNotEmpty
        ? addressController.text
        : null;

    // التحقق من الموقع إذا كان autoLocation مفعل
    if (autoLocation && (latitude == null || longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى تحديد الموقع الجغرافي")),
      );
      return;
    }

    if (widget.data['complaint_type_id'] == null ||
        widget.data['destination_id'] == null ||
        widget.data['address'] == null ||
        widget.data['lat'] == null ||
        widget.data['lng'] == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى تعبئة جميع الحقول")));
      return;
    }
    print("User token before navigating: ${widget.userToken}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintStepTwo(
          data: widget.data, // تمرير البيانات المعبأة في الخطوة الأولى
          userToken: widget.userToken, // تمرير توكن المستخدم
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).submitComplaintStep1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Builder(
                builder: (context) {
                  final localizations = AppLocalizations.of(context);
                  final isEnglish = localizations.locale.languageCode == 'en';
                  return AppTextField(
                    controller: complaintTypeController,
                    labelText: isEnglish ? "Complaint Type" : "نوع الشكوى",
                    myIcon: const Icon(Icons.list),
                    traillingIcon: PopupMenuButton<Map<String, dynamic>>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        complaintTypeController.text = value['id'];
                      },
                      itemBuilder: (context) {
                        final localizations = AppLocalizations.of(context);
                        return complaintTypes
                            .map(
                              (e) => PopupMenuItem(
                                value: e,
                                child: Text(
                                  localizations.translateComplaintType(
                                    e['name'],
                                  ),
                                ),
                              ),
                            )
                            .toList();
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                return AppTextField(
                  controller: destinationController,
                  labelText: isEnglish
                      ? "Responsible Authority"
                      : "الجهة المسؤولة",
                  myIcon: const Icon(Icons.location_city),
                  traillingIcon: PopupMenuButton<Map<String, dynamic>>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (value) {
                      destinationController.text = value['id'];
                    },
                    itemBuilder: (context) {
                      final localizations = AppLocalizations.of(context);
                      return destinations
                          .map(
                            (e) => PopupMenuItem(
                              value: e,
                              child: Text(
                                localizations.translateDestination(e['name']),
                              ),
                            ),
                          )
                          .toList();
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                return AppTextField(
                  controller: addressController,
                  labelText: isEnglish ? "Address" : "العنوان",
                  myIcon: const Icon(Icons.place),
                );
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Checkbox(
                    value: autoLocation,
                    onChanged: (value) async {
                      setState(() {
                        autoLocation = value ?? false;
                      });
                      if (autoLocation) {
                        await getCurrentLocation();
                      } else {
                        latitude = null;
                        longitude = null;
                        widget.data.remove('lat');
                        widget.data.remove('lng');
                      }
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final localizations = AppLocalizations.of(context);
                      final isEnglish =
                          localizations.locale.languageCode == 'en';
                      return Text(
                        isEnglish
                            ? "Auto-detect location"
                            : "تحديد الموقع تلقائيًا",
                      );
                    },
                  ),
                  if (fetchingLocation)
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                return AppButton(
                  text: isEnglish ? "Next" : "التالي",
                  onTap: submitData,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ComplaintStepTwo extends StatefulWidget {
  final Map data;
  final String userToken;
  const ComplaintStepTwo({
    super.key,
    required this.data,
    required this.userToken,
  });

  @override
  State<ComplaintStepTwo> createState() => _ComplaintStepTwoState();
}

class _ComplaintStepTwoState extends State<ComplaintStepTwo> {
  final descCtrl = TextEditingController();
  List<File> images = [];
  List<File> documents = [];
  bool sending = false;

  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null) {
      images = result.paths.map((e) => File(e!)).toList();
      setState(() {});
    }
  }

  Future<void> pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      documents = result.paths.map((e) => File(e!)).toList();
      setState(() {});
    }
  }

  Future<void> send() async {
    if (descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("يرجى كتابة وصف المشكلة")));
      return;
    }

    setState(() => sending = true);
    final success = await sendComplainService.sendComplaint(
      data: {...widget.data, "description": descCtrl.text.trim()},
      images: images,
      documents: documents,
      token: widget.userToken,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "تم إرسال الشكوى بنجاح ✅" : "فشل إرسال الشكوى"),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ComplaintsPage(data: {}, userToken: ''),
        ),
      );
    }

    setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).submitComplaintStep2),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "وصف المشكلة",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Gap(6),

            TextField(
              controller: descCtrl,
              maxLines: 5,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black,
              ),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.blue.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue, width: 1.5),
                ),
              ),
            ),
            Gap(20),

            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                return Text(
                  isEnglish ? "Attach Photos" : "إرفاق صور",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                );
              },
            ),
            Gap(6),
            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                return ElevatedButton.icon(
                  onPressed: pickImages,
                  icon: Icon(Icons.image),
                  label: Text(isEnglish ? "Choose Photos" : "اختيار صور"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                if (images.isEmpty) return const SizedBox.shrink();
                return Text(
                  isEnglish
                      ? "${images.length} photo(s) selected"
                      : "${images.length} صورة مختارة",
                );
              },
            ),
            Gap(20),

            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                return Text(
                  isEnglish ? "Attach Documents" : "إرفاق وثائق",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                );
              },
            ),
            Gap(6),
            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                return ElevatedButton.icon(
                  onPressed: pickDocuments,
                  icon: Icon(Icons.attach_file),
                  label: Text(isEnglish ? "Choose Files" : "اختيار ملفات"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                if (documents.isEmpty) return const SizedBox.shrink();
                return Text(
                  isEnglish
                      ? "${documents.length} file(s) selected"
                      : "${documents.length} ملف مختار",
                );
              },
            ),
            Gap(30),

            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                final isEnglish = localizations.locale.languageCode == 'en';
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: sending ? null : send,
                    child: sending
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(isEnglish ? "Send Complaint" : "إرسال الشكوى"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
