import '../../metrics/domain/user_metrics.dart';

class LinkedStudent {
  const LinkedStudent({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.linkStatus,
    this.metrics,
    this.assignedTasksCount = 0,
    this.submittedCount = 0,
    this.gradedCount = 0,
  });

  final int id;
  final int studentId;
  final String studentName;
  final String studentEmail;
  final String linkStatus;
  final UserMetrics? metrics;
  final int assignedTasksCount;
  final int submittedCount;
  final int gradedCount;

  factory LinkedStudent.fromJson(Map<String, dynamic> json) {
    return LinkedStudent(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String,
      studentEmail: json['student_email'] as String,
      linkStatus: json['link_status'] as String,
      metrics: json['metrics'] == null
          ? null
          : UserMetrics.fromJson(Map<String, dynamic>.from(json['metrics'] as Map)),
      assignedTasksCount: json['assigned_tasks_count'] as int? ?? 0,
      submittedCount: json['submitted_count'] as int? ?? 0,
      gradedCount: json['graded_count'] as int? ?? 0,
    );
  }
}
