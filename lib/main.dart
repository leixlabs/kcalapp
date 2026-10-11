import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'data/database/database.dart';
import 'features/diary/data/meal_dao.dart';
import 'features/diary/data/meal_review_dao.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app.dart';
import 'app/app_language.dart';
import 'app/providers.dart';
import 'core/utils/app_user_agent.dart';
import 'data/database/app_settings_dao.dart';
import 'l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferredLocale = PlatformDispatcher.instance.locale;
  final startupDatabase = AppDatabase();
  late final AppLanguage appLanguage;
  late final AppLocalizations l10n;
  try {
    appLanguage = AppLanguage.fromStorageValue(
      await AppSettingsDao(startupDatabase).getValue('app_language'),
    );
    final locale = appLanguage.resolveLocale(preferredLocale);
    Intl.defaultLocale = locale.languageCode;
    await initializeDateFormatting('zh', null);
    await initializeDateFormatting('en', null);
    l10n = await AppLocalizations.delegate.load(locale);
    await MealDao(startupDatabase).markInterruptedAiRecognitionsFailed(
      failedName: l10n.mealDbRecognitionFailed,
    );
    await MealReviewDao(startupDatabase).markInterruptedRefreshesFailed();
  } finally {
    await startupDatabase.close();
  }

  runApp(
    ProviderScope(
      overrides: [
        appLanguageProvider.overrideWith((ref) => appLanguage),
        userAgentProvider.overrideWithValue(await _buildUserAgent()),
      ],
      child: const CaloryApp(),
    ),
  );
}

/// 读取包版本，构造形如 `kcalapp/0.1.0+1 (iOS 17.4.1)` 的 `User-Agent`。
Future<String> _buildUserAgent() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final version = info.buildNumber.isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
    return AppUserAgent.current(version: version);
  } catch (_) {
    // 平台信息不可用时退回兜底版本号。
    return AppUserAgent.current();
  }
}
