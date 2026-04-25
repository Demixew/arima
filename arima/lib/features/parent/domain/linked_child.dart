import '../../metrics/domain/user_metrics.dart';
import '../../../core/domain/weekly_narrative.dart';

class LinkedChild {
  const LinkedChild({
    required this.id,
    required this.childId,
    required this.childName,
    required this.childEmail,
    required this.linkStatus,
    this.metrics,
    this.recentTasks = const [],
    this.positiveSignal,
    this.attentionSignal,
    this.recommendedAction,
    this.supportSummary,
    this.needsAttention = false,
    this.weeklyNarrative,
  });

  final int id;
  final int childId;
  final String childName;
  final String childEmail;
  final String linkStatus;
  final UserMetrics? metrics;
  final List<Map<String, dynamic>> recentTasks;
  final String? positiveSignal;
  final String? attentionSignal;
  final String? recommendedAction;
  final String? supportSummary;
  final bool needsAttention;
  final WeeklyNarrative? weeklyNarrative;

  factory LinkedChild.fromJson(Map<String, dynamic> json) {
    return LinkedChild(
      id: json['id'] as int,
      childId: json['child_id'] as int,
      childName: json['child_name'] as String,
      childEmail: json['child_email'] as String,
      linkStatus: json['link_status'] as String,
      metrics: json['metrics'] == null
          ? null
          : UserMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      recentTasks: json['recent_tasks'] == null
          ? []
          : List<Map<String, dynamic>>.from(
              (json['recent_tasks'] as List).map((e) => Map<String, dynamic>.from(e as Map))),
      positiveSignal: json['positive_signal'] as String?,
      attentionSignal: json['attention_signal'] as String?,
      recommendedAction: json['recommended_action'] as String?,
      supportSummary: json['support_summary'] as String?,
      needsAttention: json['needs_attention'] as bool? ?? false,
      weeklyNarrative: json['weekly_narrative'] == null
          ? null
          : WeeklyNarrative.fromJson(
              Map<String, dynamic>.from(json['weekly_narrative'] as Map),
            ),
    );
  }
}
