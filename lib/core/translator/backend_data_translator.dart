import 'package:flutter/material.dart';

class BackendDataTranslator {
  static const Map<String, Map<String, String>> _translations = {
    'complaint_types': {
      'Service Delay': 'تأخير الخدمة',
      'Misconduct': 'سوء السلوك',
      'Billing Issue': 'مشكلة الفوترة',
      'Technical Problem': 'مشكلة تقنية',
      'Other': 'أخرى',
    },
    'destinations': {
      'Ministry of Energy': 'وزارة الطاقة',
      'Ministry of Interior': 'وزارة الداخلية',
    },
    'status': {
      'pending': 'قيد الانتظار',
      'in_progress': 'قيد المعالجة',
      'in progress': 'قيد المعالجة',
      'resolved': 'تم الحل',
      'closed': 'مغلق',
      'rejected': 'مرفوضة',
      'completed': 'مكتملة',
      'new': 'جديدة',
      'newstatus': 'جديدة',
      'new status': 'جديدة',
    },
  };

  static String translateComplaintType(String englishName, Locale locale) {
    if (locale.languageCode == 'en') {
      return englishName;
    }
    return _translations['complaint_types']?[englishName] ?? englishName;
  }

  static String translateDestination(String englishName, Locale locale) {
    if (locale.languageCode == 'en') {
      return englishName;
    }
    return _translations['destinations']?[englishName] ?? englishName;
  }

  static String translateStatus(String englishStatus, Locale locale) {
    if (locale.languageCode == 'en') {
      return englishStatus;
    }
    final normalizedStatus = englishStatus.toLowerCase().trim();
    final statusMap = _translations['status'];
    if (statusMap == null) {
      return englishStatus;
    }
    final translated = statusMap[normalizedStatus];
    if (translated != null) {
      return translated;
    }
    final normalizedWithUnderscore = normalizedStatus.replaceAll(' ', '_');
    return statusMap[normalizedWithUnderscore] ?? englishStatus;
  }

  static String translateBackendValue(
    String category,
    String englishValue,
    Locale locale,
  ) {
    if (locale.languageCode == 'en') {
      return englishValue;
    }
    return _translations[category]?[englishValue] ?? englishValue;
  }
}
