class LlmProfile {
  final int? id;
  final String displayName;
  final String baseUrl;
  final String model;
  final int timeoutSeconds;
  final bool isActive;
  final DateTime createdAt;
  /// 是否在请求体中添加 `response_format: {"type": "json_object"}`。
  /// 开启后模型被强制返回合法 JSON，避免输出 markdown 代码块等非结构化内容。
  /// 不支持该参数的服务（如部分本地模型）请关闭此选项。
  final bool useJsonMode;

  const LlmProfile({
    this.id,
    required this.displayName,
    required this.baseUrl,
    required this.model,
    this.timeoutSeconds = 30,
    this.isActive = false,
    required this.createdAt,
    this.useJsonMode = true,
  });

  LlmProfile copyWith({
    int? id,
    String? displayName,
    String? baseUrl,
    String? model,
    int? timeoutSeconds,
    bool? isActive,
    DateTime? createdAt,
    bool? useJsonMode,
  }) {
    return LlmProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      useJsonMode: useJsonMode ?? this.useJsonMode,
    );
  }
}
