import 'task_status.dart';
import 'task_review_mode.dart';
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
    this.difficultyLevel = 2,
    this.estimatedTimeMinutes,
    this.antiFatigueEnabled = false,
    this.isChallenge = false,
    this.challengeTitle,
    this.challengeCategory,
    this.challengeBonusXp = 0,
    this.reviewMode = TaskReviewMode.teacherOnly,
    this.evaluationCriteria,
    this.rescuePlan,
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
  final int difficultyLevel;
  final int? estimatedTimeMinutes;
  final bool antiFatigueEnabled;
  final bool isChallenge;
  final String? challengeTitle;
  final String? challengeCategory;
  final int challengeBonusXp;
  final TaskReviewMode reviewMode;
  final String? evaluationCriteria;
  final TaskRescuePlan? rescuePlan;
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
      difficultyLevel: json['difficulty_level'] as int? ?? 2,
      estimatedTimeMinutes: json['estimated_time_minutes'] as int?,
      antiFatigueEnabled: json['anti_fatigue_enabled'] as bool? ?? false,
      isChallenge: json['is_challenge'] as bool? ?? false,
      challengeTitle: json['challenge_title'] as String?,
      challengeCategory: json['challenge_category'] as String?,
      challengeBonusXp: json['challenge_bonus_xp'] as int? ?? 0,
      reviewMode: TaskReviewMode.fromApiValue(
        json['review_mode'] as String? ?? 'teacher_only',
      ),
      evaluationCriteria: json['evaluation_criteria'] as String?,
      rescuePlan: json['rescue_plan'] == null
          ? null
          : TaskRescuePlan.fromJson(
              Map<String, dynamic>.from(json['rescue_plan'] as Map),
            ),
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

class TaskRescuePlan {
  const TaskRescuePlan({
    this.miniSteps = const [],
    this.recommendedNewTimeBlock,
    this.difficultyTone,
  });

  final List<String> miniSteps;
  final String? recommendedNewTimeBlock;
  final String? difficultyTone;

  factory TaskRescuePlan.fromJson(Map<String, dynamic> json) {
    return TaskRescuePlan(
      miniSteps: (json['mini_steps'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
      recommendedNewTimeBlock: json['recommended_new_time_block'] as String?,
      difficultyTone: json['difficulty_tone'] as String?,
    );
  }
}
