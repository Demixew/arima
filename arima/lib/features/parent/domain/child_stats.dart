import 'package:flutter/foundation.dart';

@immutable
class ChildStats {
  const ChildStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.currentStreak,
    required this.completionRate,
    this.lastActivity,
  });

  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int currentStreak;
  final int completionRate;
  final DateTime? lastActivity;

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
    );
  }
}
