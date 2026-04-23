class TaskReminder {
  const TaskReminder({
    required this.id,
    required this.isEnabled,
    required this.remindAfterHours,
    required this.maxMissedCount,
    required this.missedCount,
    required this.lastRemindedAt,
    required this.escalatedToParent,
    required this.parentAlertMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final bool isEnabled;
  final int remindAfterHours;
  final int maxMissedCount;
  final int missedCount;
  final DateTime? lastRemindedAt;
  final bool escalatedToParent;
  final String? parentAlertMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TaskReminder.fromJson(Map<String, dynamic> json) {
    return TaskReminder(
      id: json['id'] as int,
      isEnabled: json['is_enabled'] as bool? ?? true,
      remindAfterHours: json['remind_after_hours'] as int? ?? 6,
      maxMissedCount: json['max_missed_count'] as int? ?? 3,
      missedCount: json['missed_count'] as int? ?? 0,
      lastRemindedAt: json['last_reminded_at'] == null
          ? null
          : DateTime.parse(json['last_reminded_at'] as String),
      escalatedToParent: json['escalated_to_parent'] as bool? ?? false,
      parentAlertMessage: json['parent_alert_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}