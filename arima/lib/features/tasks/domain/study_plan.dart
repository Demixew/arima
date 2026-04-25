import '../../../core/domain/weekly_narrative.dart';

class StudyPlan {
  const StudyPlan({
    required this.focusMessage,
    this.doNow = const [],
    this.doNext = const [],
    this.stretchGoal,
    this.estimatedTotalMinutes = 0,
    this.mainSkillToImprove,
    this.weeklyNarrative,
  });

  final String focusMessage;
  final List<StudyPlanTaskRef> doNow;
  final List<StudyPlanTaskRef> doNext;
  final String? stretchGoal;
  final int estimatedTotalMinutes;
  final String? mainSkillToImprove;
  final WeeklyNarrative? weeklyNarrative;

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    return StudyPlan(
      focusMessage: json['focus_message'] as String? ?? '',
      doNow: (json['do_now'] as List<dynamic>? ?? const [])
          .map((dynamic item) => StudyPlanTaskRef.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      doNext: (json['do_next'] as List<dynamic>? ?? const [])
          .map((dynamic item) => StudyPlanTaskRef.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      stretchGoal: json['stretch_goal'] as String?,
      estimatedTotalMinutes: json['estimated_total_minutes'] as int? ?? 0,
      mainSkillToImprove: json['main_skill_to_improve'] as String?,
      weeklyNarrative: json['weekly_narrative'] == null
          ? null
          : WeeklyNarrative.fromJson(
              Map<String, dynamic>.from(json['weekly_narrative'] as Map),
            ),
    );
  }
}

class StudyPlanTaskRef {
  const StudyPlanTaskRef({
    required this.id,
    required this.title,
    required this.status,
    this.dueAt,
    this.difficultyLevel = 2,
    this.estimatedTimeMinutes,
  });

  final int id;
  final String title;
  final String status;
  final DateTime? dueAt;
  final int difficultyLevel;
  final int? estimatedTimeMinutes;

  factory StudyPlanTaskRef.fromJson(Map<String, dynamic> json) {
    return StudyPlanTaskRef(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      difficultyLevel: json['difficulty_level'] as int? ?? 2,
      estimatedTimeMinutes: json['estimated_time_minutes'] as int?,
    );
  }
}
