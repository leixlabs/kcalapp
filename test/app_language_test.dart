import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calory/app/app_language.dart';

void main() {
  group('AppLanguage', () {
    test(
      'restores saved language values and defaults unknown values to system',
      () {
        expect(AppLanguage.fromStorageValue('zh'), AppLanguage.chinese);
        expect(AppLanguage.fromStorageValue('en'), AppLanguage.english);
        expect(AppLanguage.fromStorageValue('system'), AppLanguage.system);
        expect(AppLanguage.fromStorageValue(null), AppLanguage.system);
        expect(AppLanguage.fromStorageValue('unsupported'), AppLanguage.system);
      },
    );

    test('resolves system language to a supported locale', () {
      expect(
        AppLanguage.system.resolveLocale(const Locale('zh', 'Hans')),
        const Locale('zh'),
      );
      expect(
        AppLanguage.system.resolveLocale(const Locale('fr')),
        const Locale('en'),
      );
      expect(
        AppLanguage.chinese.resolveLocale(const Locale('en')),
        const Locale('zh'),
      );
    });
  });
}
