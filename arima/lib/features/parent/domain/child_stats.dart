import 'package:flutter/foundation.dart';

import '../../../core/domain/weekly_narrative.dart';
import '../../metrics/domain/gamification_profile.dart';

@immutable
class ChildStats {
  const ChildStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.currentStreak,
    required this.completionRate,
    this.lastActivity,
    this.gamification,
    this.positiveSignal,
    this.attentionSignal,
    this.recommendedAction,
    this.supportSummary,
    this.weeklyNarrative,
  });

  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int currentStreak;
  final int completionRate;
  final DateTime? lastActivity;
  final GamificationProfile? gamification;
  final String? positiveSignal;
  final String? attentionSignal;
  final String? recommendedAction;
  final String? supportSummary;
  final WeeklyNarrative? weeklyNarrative;

  factory ChildStats.fromJson(Map<String, dynamic> json) {
    return ChildStats(
      totalTasks: json['total_tasks'] as int? ?? 0,
      completedTasks: json['completed_tasks'] as int? ?? 0,
      overdueTasks: json['overdue_tasks'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      completionRate: json['completion_rate'] as int? ?? 0,
      lastActivity: json['last_activity'] == null
          ? null
          : DateTime.parse(json['last_activity'] as String),
      gamification: json['gamification'] == null
          ? null
          : GamificationProfile.fromJson(
              Map<String, dynamic>.from(json['gamification'] as Map),
            ),
      positiveSignal: json['positive_signal'] as String?,
      attentionSignal: json['attention_signal'] as String?,
      recommendedAction: json['recommended_action'] as String?,
      supportSummary: json['support_summary'] as String?,
      weeklyNarrative: json['weekly_narrative'] == null
          ? null
          : WeeklyNarrative.fromJson(
              Map<String, dynamic>.from(json['weekly_narrative'] as Map),
            ),
    );
  }
}
