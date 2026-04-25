class AISubmissionReview {
  const AISubmissionReview({
    required this.grade,
    required this.feedback,
    required this.model,
    required this.checkedAt,
  });

  final int grade;
  final String feedback;
  final String model;
  final DateTime checkedAt;

  factory AISubmissionReview.fromJson(Map<String, dynamic> json) {
    return AISubmissionReview(
      grade: json['grade'] as int,
      feedback: json['feedback'] as String,
      model: json['model'] as String? ?? '',
      checkedAt: DateTime.parse(json['checked_at'] as String),
    );
  }
}
