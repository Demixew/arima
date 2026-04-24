class AITaskDraft {
  const AITaskDraft({
    required this.title,
    required this.description,
    required this.requiresSubmission,
    required this.model,
  });

  final String title;
  final String description;
  final bool requiresSubmission;
  final String model;

  factory AITaskDraft.fromJson(Map<String, dynamic> json) {
    return AITaskDraft(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      requiresSubmission: json['requires_submission'] as bool? ?? false,
      model: json['model'] as String? ?? '',
    );
  }
}
