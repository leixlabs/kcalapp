import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database/database.dart';
import 'features/diary/data/meal_dao.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  final startupDatabase = AppDatabase();
  try {
    await MealDao(startupDatabase).markInterruptedAiRecognitionsFailed();
  } finally {
    await startupDatabase.close();
  }
  runApp(const ProviderScope(child: CaloryApp()));
}
