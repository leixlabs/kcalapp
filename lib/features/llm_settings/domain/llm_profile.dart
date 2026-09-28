class LlmProfile {
  final int? id;
  final String displayName;
  final String baseUrl;
  final String model;
  final int timeoutSeconds;
  final bool isActive;
  final DateTime createdAt;

  const LlmProfile({
    this.id,
    required this.displayName,
    required this.baseUrl,
    required this.model,
    this.timeoutSeconds = 30,
    this.isActive = false,
    required this.createdAt,
  });

  LlmProfile copyWith({
    int? id,
    String? displayName,
    String? baseUrl,
    String? model,
    int? timeoutSeconds,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return LlmProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
