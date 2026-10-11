import 'package:flutter/widgets.dart';

enum AppLanguage {
  system,
  chinese,
  english;

  static AppLanguage fromStorageValue(String? value) => switch (value) {
    'zh' => AppLanguage.chinese,
    'en' => AppLanguage.english,
    _ => AppLanguage.system,
  };

  String get storageValue => switch (this) {
    AppLanguage.system => 'system',
    AppLanguage.chinese => 'zh',
    AppLanguage.english => 'en',
  };

  Locale? get locale => switch (this) {
    AppLanguage.system => null,
    AppLanguage.chinese => const Locale('zh'),
    AppLanguage.english => const Locale('en'),
  };

  Locale resolveLocale(Locale systemLocale) =>
      locale ??
      Locale(systemLocale.languageCode.toLowerCase() == 'zh' ? 'zh' : 'en');
}
