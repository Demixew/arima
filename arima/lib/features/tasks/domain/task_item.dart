import 'task_status.dart';
import 'task_reminder.dart';
import '../../teacher/domain/task_submission.dart';

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dueAt,
    required this.ownerId,
    this.assignedByTeacherId,
    this.requiresSubmission = false,
    this.submission,
    required this.reminder,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String? description;
  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final int ownerId;
  final int? assignedByTeacherId;
  final bool requiresSubmission;
  final TaskSubmission? submission;
  final TaskReminder? reminder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromApiValue(json['status'] as String),
      dueAt: json['due_at'] == null ? null : DateTime.parse(json['due_at'] as String),
      ownerId: json['owner_id'] as int,
      assignedByTeacherId: json['assigned_by_teacher_id'] as int?,
      requiresSubmission: json['requires_submission'] as bool? ?? false,
      submission: json['submission'] == null
          ? null
          : TaskSubmission.fromJson(Map<String, dynamic>.from(json['submission'] as Map)),
      reminder: json['reminder'] == null
          ? null
          : TaskReminder.fromJson(Map<String, dynamic>.from(json['reminder'] as Map)),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
