import 'package:flutter/material.dart';

enum AppLanguage { english, vietnamese }

class AppLocale {
  AppLocale._();

  static final ValueNotifier<AppLanguage> language =
      ValueNotifier(AppLanguage.english);

  static bool get isVietnamese => language.value == AppLanguage.vietnamese;

  static Locale get locale =>
      isVietnamese ? const Locale('vi', 'VN') : const Locale('en', 'US');

  static void toggle() {
    language.value =
        isVietnamese ? AppLanguage.english : AppLanguage.vietnamese;
  }

  static String text(String english, String vietnamese) =>
      isVietnamese ? vietnamese : english;
}
