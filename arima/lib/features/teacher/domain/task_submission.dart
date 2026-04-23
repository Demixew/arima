class TaskSubmission {
  const TaskSubmission({
    required this.id,
    required this.taskId,
    required this.studentId,
    this.submissionText,
    this.imageUrl,
    required this.isGraded,
    this.grade,
    this.feedback,
    required this.submittedAt,
    this.gradedAt,
  });

  final int id;
  final int taskId;
  final int studentId;
  final String? submissionText;
  final String? imageUrl;
  final bool isGraded;
  final int? grade;
  final String? feedback;
  final DateTime submittedAt;
  final DateTime? gradedAt;

  factory TaskSubmission.fromJson(Map<String, dynamic> json) {
    return TaskSubmission(
      id: json['id'] as int,
      taskId: json['task_id'] as int,
      studentId: json['student_id'] as int,
      submissionText: json['submission_text'] as String?,
      imageUrl: json['image_url'] as String?,
      isGraded: json['is_graded'] as bool? ?? false,
      grade: json['grade'] as int?,
      feedback: json['feedback'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      gradedAt: json['graded_at'] == null
          ? null
          : DateTime.parse(json['graded_at'] as String),
    );
  }
}
