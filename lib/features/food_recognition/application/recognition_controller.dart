import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/llm/llm_adapter.dart';
import '../../../data/llm/llm_schema.dart';
import '../../../platform/camera/camera_gateway.dart';
import '../../diary/domain/meal_type.dart';
import '../presentation/recognition_result_page.dart';

class RecognitionController {
  final Ref _ref;

  RecognitionController(this._ref);

  Future<MediaResult?> takePhoto() async {
    final cameraGateway = _ref.read(cameraGatewayProvider);
    return cameraGateway.takePhoto();
  }

  Future<MediaResult?> pickFromGallery() async {
    final mediaPicker = _ref.read(mediaPickerGatewayProvider);
    return mediaPicker.pickFromGallery();
  }

  /// 校验 LLM 是否已配置（存在 active profile 且 API Key 非空）。
  /// 用于在调用相机/相册前给出友好提示，避免进入 "AI 识别中" 流程后才报错。
  Future<bool> isLlmConfigured() async {
    final llmProfileDao = _ref.read(llmProfileDaoProvider);
    final secureStore = _ref.read(secureStoreProvider);
    final profile = await llmProfileDao.getActive();
    if (profile == null) return false;
    final apiKey = await secureStore.read('${profile.id}');
    return apiKey != null && apiKey.isNotEmpty;
  }

  Future<void> recognize(String photoPath, {MealType? mealTypeHint, CancelToken? cancelToken}) async {
    final imageProcessor = _ref.read(imageProcessorProvider);
    final llmAdapter = _ref.read(llmAdapterProvider);
    final llmProfileDao = _ref.read(llmProfileDaoProvider);
    final secureStore = _ref.read(secureStoreProvider);

    final profile = await llmProfileDao.getActive();
    if (profile == null) {
      throw RecognitionFailedException('请先在设置中配置 LLM 服务');
    }
    final apiKey = await secureStore.read('${profile.id}');
    if (apiKey == null || apiKey.isEmpty) {
      throw RecognitionFailedException('请先在设置中配置 API Key');
    }

    final processed = await imageProcessor.processImage(sourcePath: photoPath);

    final hint = _toHint(mealTypeHint);
    try {
      final result = await llmAdapter.recognizeFood(
        profile: profile,
        apiKey: apiKey,
        imagePath: processed.path,
        mealTypeHint: hint,
        cancelToken: cancelToken,
      );

      final draft = LlmSchemaValidator.toDraft(
        result,
        photoTempPath: photoPath,
        mealType: mealTypeHint ?? MealType.guessFromHour(DateTime.now().hour),
      );
      _ref.read(recognitionDraftProvider.notifier).state = draft;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw RecognitionCancelledException();
      }
      rethrow;
    }
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

/// 用户主动取消识别时抛出，便于 UI 区分取消与失败。
class RecognitionCancelledException implements Exception {
  @override
  String toString() => '识别已取消';
}

final recognitionControllerProvider = Provider<RecognitionController>((ref) {
  return RecognitionController(ref);
});
