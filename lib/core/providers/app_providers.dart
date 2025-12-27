import 'package:flutter/material.dart';
import 'package:flutter_internet_application/core/providers/theme_provider.dart';
import 'package:flutter_internet_application/core/providers/language_provider.dart';

class AppProviders extends InheritedWidget {
  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;

  const AppProviders({
    super.key,
    required this.themeProvider,
    required this.languageProvider,
    required super.child,
  });

  static AppProviders? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppProviders>();
  }

  @override
  bool updateShouldNotify(AppProviders oldWidget) {
    return themeProvider != oldWidget.themeProvider ||
        languageProvider != oldWidget.languageProvider;
  }
}
