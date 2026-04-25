import '../../metrics/domain/user_metrics.dart';
import '../../../core/domain/weekly_narrative.dart';

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
    this.riskScore = 0,
    this.riskLevel = 'stable',
    this.riskReason = '',
    this.aiTrend,
    this.weeklyNarrative,
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
  final int riskScore;
  final String riskLevel;
  final String riskReason;
  final AiTrendSummary? aiTrend;
  final WeeklyNarrative? weeklyNarrative;

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
      riskScore: json['risk_score'] as int? ?? 0,
      riskLevel: json['risk_level'] as String? ?? 'stable',
      riskReason: json['risk_reason'] as String? ?? '',
      aiTrend: json['ai_trend'] == null
          ? null
          : AiTrendSummary.fromJson(
              Map<String, dynamic>.from(json['ai_trend'] as Map),
            ),
      weeklyNarrative: json['weekly_narrative'] == null
          ? null
          : WeeklyNarrative.fromJson(
              Map<String, dynamic>.from(json['weekly_narrative'] as Map),
            ),
    );
  }
}

class AiTrendSummary {
  const AiTrendSummary({
    this.weakestArea,
    this.trendSummary,
    this.riskFlagCount = 0,
    this.reviewedCount = 0,
  });

  final String? weakestArea;
  final String? trendSummary;
  final int riskFlagCount;
  final int reviewedCount;

  factory AiTrendSummary.fromJson(Map<String, dynamic> json) {
    return AiTrendSummary(
      weakestArea: json['weakest_area'] as String?,
      trendSummary: json['trend_summary'] as String?,
      riskFlagCount: json['risk_flag_count'] as int? ?? 0,
      reviewedCount: json['reviewed_count'] as int? ?? 0,
    );
  }
}
