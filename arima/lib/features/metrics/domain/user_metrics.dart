import 'gamification_profile.dart';

class UserMetrics {
  const UserMetrics({
    required this.totalTasksCompleted,
    required this.totalTasksCreated,
    required this.currentStreak,
    required this.longestStreak,
    required this.avgCompletionTimeHours,
    required this.totalFocusTimeMinutes,
    required this.completionRate,
    this.lastCompletedAt,
    this.lastActivityAt,
    this.gamification,
  });

  final int totalTasksCompleted;
  final int totalTasksCreated;
  final int currentStreak;
  final int longestStreak;
  final double avgCompletionTimeHours;
  final int totalFocusTimeMinutes;
  final int completionRate;
  final DateTime? lastCompletedAt;
  final DateTime? lastActivityAt;
  final GamificationProfile? gamification;

  factory UserMetrics.fromJson(Map<String, dynamic> json) {
    return UserMetrics(
      totalTasksCompleted: json['total_tasks_completed'] as int? ?? 0,
      totalTasksCreated: json['total_tasks_created'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      avgCompletionTimeHours: (json['avg_completion_time_hours'] as num?)?.toDouble() ?? 0.0,
      totalFocusTimeMinutes: json['total_focus_time_minutes'] as int? ?? 0,
      completionRate: json['completion_rate'] as int? ?? 0,
      lastCompletedAt: json['last_completed_at'] == null
          ? null
          : DateTime.parse(json['last_completed_at'] as String),
      lastActivityAt: json['last_activity_at'] == null
          ? null
          : DateTime.parse(json['last_activity_at'] as String),
      gamification: json['gamification'] == null
          ? null
          : GamificationProfile.fromJson(
              Map<String, dynamic>.from(json['gamification'] as Map),
            ),
    );
  }
}
