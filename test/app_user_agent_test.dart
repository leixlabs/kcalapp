import 'package:calory/core/utils/app_user_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserAgent.build', () {
    test('包含产品标识、版本号与平台', () {
      expect(
        AppUserAgent.build(
          version: '0.1.0+1',
          platform: 'iOS',
          platformVersion: '17.4.1',
        ),
        'kcalapp/0.1.0+1 (iOS 17.4.1)',
      );
    });

    test('平台版本未知时只保留平台名', () {
      expect(
        AppUserAgent.build(version: '0.1.0', platform: 'Android'),
        'kcalapp/0.1.0 (Android)',
      );
      expect(
        AppUserAgent.build(
          version: '0.1.0',
          platform: 'Android',
          platformVersion: '',
        ),
        'kcalapp/0.1.0 (Android)',
      );
    });
  });

  group('AppUserAgent.platformName', () {
    test('映射已知平台', () {
      expect(AppUserAgent.platformName('ios'), 'iOS');
      expect(AppUserAgent.platformName('android'), 'Android');
      expect(AppUserAgent.platformName('macos'), 'macOS');
    });

    test('未知平台回退为 Unknown', () {
      expect(AppUserAgent.platformName('plan9'), 'Unknown');
    });
  });

  group('AppUserAgent.platformVersionFrom', () {
    test('从 iOS 系统版本串中提取版本号', () {
      expect(
        AppUserAgent.platformVersionFrom('Version 17.4.1 (Build 21E236)'),
        '17.4.1',
      );
    });

    test('把下划线归一化为点号', () {
      expect(AppUserAgent.platformVersionFrom('10_15_7'), '10.15.7');
    });

    test('无数字时返回 null', () {
      expect(AppUserAgent.platformVersionFrom('unknown'), isNull);
    });
  });
}
