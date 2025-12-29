import 'package:flutter/material.dart';
import 'package:flutter_internet_application/core/translator/backend_data_translator.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'login': 'Login',
      'logout': 'Logout',
      'password': 'Password',
      'createAccount': 'Create account',
      'usersComplaints': 'User\'s complaints',
      'mobileNumberOrEmail': 'Mobile number or email',
      'submitComplaintStep1': 'Submit a complaint - Step 1',
      'submitComplaintStep2': 'Submit a complaint - Step 2',
      'appTitle': 'Citizen service app',
      'newStatus': 'New',
      'inProgress': 'In Progress',
      'rejected': 'Rejected',
      'completed': 'Completed',
      'problemDescription': 'Problem Description',
    },
    'ar': {
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'password': 'كلمة المرور',
      'createAccount': 'إنشاء حساب',
      'usersComplaints': 'شكاوي المستخدم',
      'mobileNumberOrEmail': 'رقم الهاتف أو الإيميل',
      'submitComplaintStep1': 'تقديم شكوى - الخطوة الأولى',
      'submitComplaintStep2': 'تقديم شكوى - الخطوة الثانية',
      'appTitle': 'تطبيق خدمة المواطن',
      'newStatus': 'جديدة',
      'inProgress': 'قيد المعالجة',
      'rejected': 'مرفوضة',
      'completed': 'مكتملة',
      'problemDescription': 'وصف المشكلة',
    },
  };

  String get login => _localizedValues[locale.languageCode]!['login']!;

  String get logout => _localizedValues[locale.languageCode]!['logout']!;

  String get password => _localizedValues[locale.languageCode]!['password']!;

  String get createAccount =>
      _localizedValues[locale.languageCode]!['createAccount']!;

  String get usersComplaints =>
      _localizedValues[locale.languageCode]!['usersComplaints']!;

  String get mobileNumberOrEmail =>
      _localizedValues[locale.languageCode]!['mobileNumberOrEmail']!;

  String get submitComplaintStep1 =>
      _localizedValues[locale.languageCode]!['submitComplaintStep1']!;

  String get submitComplaintStep2 =>
      _localizedValues[locale.languageCode]!['submitComplaintStep2']!;
  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;

  String get newStatus => _localizedValues[locale.languageCode]!['newStatus']!;

  String get inProgress =>
      _localizedValues[locale.languageCode]!['inProgress']!;

  String get rejected => _localizedValues[locale.languageCode]!['rejected']!;

  String get completed => _localizedValues[locale.languageCode]!['completed']!;

  String get problemDescription =>
      _localizedValues[locale.languageCode]!['problemDescription']!;

  String translateComplaintType(String englishName) {
    return BackendDataTranslator.translateComplaintType(englishName, locale);
  }

  String translateDestination(String englishName) {
    return BackendDataTranslator.translateDestination(englishName, locale);
  }

  String translateStatus(String englishStatus) {
    return BackendDataTranslator.translateStatus(englishStatus, locale);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_) => false;
}
