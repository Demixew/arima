class TeacherMetrics {
  const TeacherMetrics({
    required this.totalStudents,
    required this.totalAssignedTasks,
    required this.totalSubmissions,
    required this.pendingGrading,
    required this.avgGrade,
  });

  final int totalStudents;
  final int totalAssignedTasks;
  final int totalSubmissions;
  final int pendingGrading;
  final double avgGrade;

  factory TeacherMetrics.fromJson(Map<String, dynamic> json) {
    return TeacherMetrics(
      totalStudents: json['total_students'] as int? ?? 0,
      totalAssignedTasks: json['total_assigned_tasks'] as int? ?? 0,
      totalSubmissions: json['total_submissions'] as int? ?? 0,
      pendingGrading: json['pending_grading'] as int? ?? 0,
      avgGrade: (json['avg_grade'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
