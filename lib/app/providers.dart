import 'package:alice/alice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../features/diary/data/meal_dao.dart';
import '../features/diary/data/meal_repository.dart';
import '../features/diary/data/meal_review_dao.dart';
import '../features/diary/data/goal_dao.dart';
import '../features/diary/data/goal_repository.dart';
import '../features/llm_settings/data/llm_profile_dao.dart';
import '../platform/secure_store/secure_store_gateway.dart';
import '../platform/secure_store/secure_store_impl.dart';
import '../platform/camera/camera_gateway.dart';
import '../platform/camera/camera_gateway_impl.dart';
import '../data/image/image_processor.dart';
import '../data/llm/llm_adapter.dart';

final aliceProvider = Provider<Alice>((ref) {
  return Alice(
    configuration: AliceConfiguration(
      showNotification: false,
      showInspectorOnShake: false,
    ),
  );
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final mealDaoProvider = Provider<MealDao>((ref) {
  return MealDao(ref.watch(databaseProvider));
});

final goalDaoProvider = Provider<GoalDao>((ref) {
  return GoalDao(ref.watch(databaseProvider));
});

final llmProfileDaoProvider = Provider<LlmProfileDao>((ref) {
  return LlmProfileDao(ref.watch(databaseProvider));
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(mealDaoProvider));
});

final mealReviewDaoProvider = Provider<MealReviewDao>((ref) {
  return MealReviewDao(ref.watch(databaseProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(goalDaoProvider));
});

final secureStoreProvider = Provider<SecureStoreGateway>((ref) {
  return SecureStoreImpl();
});

final cameraGatewayProvider = Provider<CameraGateway>((ref) {
  return CameraGatewayImpl();
});

final mediaPickerGatewayProvider = Provider<MediaPickerGateway>((ref) {
  return MediaPickerImpl();
});

final imageProcessorProvider = Provider<ImageProcessor>((ref) {
  return ImageProcessor();
});

final llmAdapterProvider = Provider<LlmAdapter>((ref) {
  return LlmAdapter(alice: ref.watch(aliceProvider));
});
