import 'dart:io';

/// 构造出站请求的 `User-Agent`，用于向服务端标识本 App、版本及运行平台。
///
/// 若不做处理，`dart:io` 的 `HttpClient` 会发送 `Dart/<version> (dart:io)`，
/// 多数服务端会将其视为匿名的 Dart 客户端。
class AppUserAgent {
  AppUserAgent._();

  /// product token，出现在 `User-Agent` 的开头。
  static const product = 'kcalapp';

  /// 读取不到包版本时使用的兜底版本号。
  static const fallbackVersion = '0.0.0';

  /// 按 RFC 9110 的 product token 形式拼装 `User-Agent`：
  ///
  ///   kcalapp/0.1.0+1 (iOS 17.4.1)
  ///   kcalapp/0.1.0+1 (Android 14)
  static String build({
    required String version,
    required String platform,
    String? platformVersion,
  }) {
    final os = (platformVersion == null || platformVersion.isEmpty)
        ? platform
        : '$platform $platformVersion';
    return '$product/$version ($os)';
  }

  /// 当前设备的 `User-Agent`，版本号缺省为 [fallbackVersion]。
  static String current({String version = fallbackVersion}) {
    return build(
      version: version,
      platform: platformName(Platform.operatingSystem),
      platformVersion: platformVersionFrom(Platform.operatingSystemVersion),
    );
  }

  /// 把 `Platform.operatingSystem` 的取值映射为易读的平台名。
  static String platformName(String operatingSystem) {
    switch (operatingSystem) {
      case 'ios':
        return 'iOS';
      case 'android':
        return 'Android';
      case 'macos':
        return 'macOS';
      case 'windows':
        return 'Windows';
      case 'linux':
        return 'Linux';
      case 'fuchsia':
        return 'Fuchsia';
      default:
        return 'Unknown';
    }
  }

  /// 从 `Platform.operatingSystemVersion` 的原始字符串中提取版本号，
  /// 例如 iOS 的 `Version 17.4.1 (Build 21E236)` → `17.4.1`；无则返回 `null`。
  static String? platformVersionFrom(String rawVersion) {
    final match = RegExp(r'\d+(?:[._]\d+)*').firstMatch(rawVersion);
    return match?.group(0)?.replaceAll('_', '.');
  }
}
