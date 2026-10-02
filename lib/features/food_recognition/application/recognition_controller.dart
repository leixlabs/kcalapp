import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/llm/llm_adapter.dart';
import '../../../platform/camera/camera_gateway.dart';
import '../../diary/application/diary_providers.dart';
import '../../diary/application/meal_review_controller.dart';
import '../../diary/domain/meal.dart';
import '../../diary/domain/meal_type.dart';

class RecognitionController {
  final Ref _ref;
  final Set<int> _recognizingMealIds = {};

  RecognitionController(this._ref);

  Future<MediaResult?> takePhoto() async {
    final cameraGateway = _ref.read(cameraGatewayProvider);
    return cameraGateway.takePhoto();
  }

  Future<MediaResult?> pickFromGallery() async {
    final mediaPicker = _ref.read(mediaPickerGatewayProvider);
    return mediaPicker.pickFromGallery();
  }

  Future<void> recognizeSavedMeal(
    int mealId, {
    required String photoPath,
    required MealType mealType,
  }) async {
    final imageProcessor = _ref.read(imageProcessorProvider);
    final llmAdapter = _ref.read(llmAdapterProvider);
    final mealRepository = _ref.read(mealRepositoryProvider);
    if (!_recognizingMealIds.add(mealId)) return;
    File? processedImage;
    try {
      await mealRepository.updateAiRecognition(
        mealId,
        status: AiRecognitionStatus.processing,
      );
      _invalidateDiary();

      final profile = await _ref.read(llmProfileDaoProvider).getActive();
      if (profile == null) {
        throw RecognitionFailedException('请先在设置中配置 LLM 服务');
      }
      final apiKey = await _ref.read(secureStoreProvider).read('${profile.id}');
      if (apiKey == null || apiKey.isEmpty) {
        throw RecognitionFailedException('请先在设置中配置 API Key');
      }

      processedImage = await imageProcessor.processImage(sourcePath: photoPath);
      final result = await llmAdapter.recognizeFood(
        profile: profile,
        apiKey: apiKey,
        imagePath: processedImage.path,
        mealTypeHint: _toHint(mealType),
      );
      await mealRepository.updateAiRecognition(
        mealId,
        status: AiRecognitionStatus.completed,
        result: result,
      );
      _invalidateDiary();
      unawaited(_ref.read(mealReviewControllerProvider).refreshForMeal(mealId));
    } catch (_) {
      await mealRepository.updateAiRecognition(
        mealId,
        status: AiRecognitionStatus.failed,
      );
      _invalidateDiary();
      rethrow;
    } finally {
      try {
        if (processedImage != null) {
          await imageProcessor.deleteFile(processedImage.path);
        }
      } finally {
        _recognizingMealIds.remove(mealId);
      }
    }
  }

  void _invalidateDiary() {
    _ref.invalidate(dailySummaryProvider);
    _ref.invalidate(weeklyMealsProvider);
  }

  MealTypeHint? _toHint(MealType? type) {
    if (type == null) return null;
    return MealTypeHint.values.firstWhere(
      (e) => e.name == type.name,
      orElse: () => MealTypeHint.snack,
    );
  }
}

class RecognitionFailedException implements Exception {
  final String message;
  RecognitionFailedException(this.message);
  @override
  String toString() => message;
}

final recognitionControllerProvider = Provider<RecognitionController>((ref) {
  return RecognitionController(ref);
});
