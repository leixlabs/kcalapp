enum LlmResponseFormat {
  none,
  jsonMode,
  jsonSchema;

  String get label => switch (this) {
    LlmResponseFormat.none => '关闭结构化输出',
    LlmResponseFormat.jsonMode => 'JSON Mode',
    LlmResponseFormat.jsonSchema => 'JSON Schema',
  };
}

class LlmProfile {
  final int? id;
  final String displayName;
  final String baseUrl;
  final String model;
  final int timeoutSeconds;
  final bool isActive;
  final DateTime createdAt;
  final LlmResponseFormat responseFormat;

  const LlmProfile({
    this.id,
    required this.displayName,
    required this.baseUrl,
    required this.model,
    this.timeoutSeconds = 30,
    this.isActive = false,
    required this.createdAt,
    this.responseFormat = LlmResponseFormat.jsonSchema,
  });

  bool get useJsonMode => responseFormat != LlmResponseFormat.none;

  LlmProfile copyWith({
    int? id,
    String? displayName,
    String? baseUrl,
    String? model,
    int? timeoutSeconds,
    bool? isActive,
    DateTime? createdAt,
    LlmResponseFormat? responseFormat,
  }) {
    return LlmProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      responseFormat: responseFormat ?? this.responseFormat,
    );
  }
}
