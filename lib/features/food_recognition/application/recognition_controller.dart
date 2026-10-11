import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/llm/llm_adapter.dart';
import '../../../l10n/l10n.dart';
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
    String? photoAssetId,
    String? photoPath,
    required MealType mealType,
    required AppLocalizations l10n,
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
        processingName: l10n.mealDbRecognizing,
      );
      _invalidateDiary();

      final sourcePath = await _resolveSourcePath(
        photoAssetId: photoAssetId,
        photoPath: photoPath,
      );
      if (sourcePath == null) {
        throw RecognitionFailedException(l10n.mealRecognizeNoPhoto);
      }

      final profile = await _ref.read(llmProfileDaoProvider).getActive();
      if (profile == null) {
        throw RecognitionFailedException(l10n.mealRecognizeConfigureLlm);
      }
      final apiKey = await _ref.read(secureStoreProvider).read('${profile.id}');
      if (apiKey == null || apiKey.isEmpty) {
        throw RecognitionFailedException(l10n.mealRecognizeConfigureKey);
      }

      processedImage = await imageProcessor.processImage(
        sourcePath: sourcePath,
      );
      final result = await llmAdapter.recognizeFood(
        profile: profile,
        apiKey: apiKey,
        imagePath: processedImage.path,
        language: l10n.localeName,
        mealTypeHint: _toHint(mealType),
      );
      await mealRepository.updateAiRecognition(
        mealId,
        status: AiRecognitionStatus.completed,
        result: result,
      );
      _invalidateDiary();
      unawaited(
        _ref.read(mealReviewControllerProvider).refreshForMeal(mealId, l10n),
      );
    } catch (_) {
      await mealRepository.updateAiRecognition(
        mealId,
        status: AiRecognitionStatus.failed,
        failedName: l10n.mealDbRecognitionFailed,
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

  /// 优先从系统相册资源解析文件，其次回退到沙盒路径。
  Future<String?> _resolveSourcePath({
    String? photoAssetId,
    String? photoPath,
  }) async {
    if (photoAssetId != null && photoAssetId.isNotEmpty) {
      final file = await _ref
          .read(photoLibraryGatewayProvider)
          .fileForAsset(photoAssetId);
      if (file != null) return file.path;
    }
    if (photoPath != null && photoPath.isNotEmpty) return photoPath;
    return null;
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
