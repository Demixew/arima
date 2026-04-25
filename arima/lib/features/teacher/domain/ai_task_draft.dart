class AITaskDraft {
  const AITaskDraft({
    required this.title,
    required this.description,
    required this.requiresSubmission,
    required this.difficultyLevel,
    required this.estimatedTimeMinutes,
    required this.antiFatigueEnabled,
    required this.model,
    required this.provider,
  });

  final String title;
  final String description;
  final bool requiresSubmission;
  final int difficultyLevel;
  final int? estimatedTimeMinutes;
  final bool antiFatigueEnabled;
  final String model;
  final String provider;

  factory AITaskDraft.fromJson(Map<String, dynamic> json) {
    return AITaskDraft(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      requiresSubmission: json['requires_submission'] as bool? ?? false,
      difficultyLevel: json['difficulty_level'] as int? ?? 2,
      estimatedTimeMinutes: json['estimated_time_minutes'] as int?,
      antiFatigueEnabled: json['anti_fatigue_enabled'] as bool? ?? false,
      model: json['model'] as String? ?? '',
      provider: json['provider'] as String? ?? 'builtin',
    );
  }
}
