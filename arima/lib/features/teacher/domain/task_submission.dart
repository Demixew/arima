import '../../tasks/domain/task_review_mode.dart';

class TaskSubmission {
  const TaskSubmission({
    required this.id,
    required this.taskId,
    required this.studentId,
    this.submissionText,
    this.imageUrl,
    required this.isGraded,
    this.grade,
    this.feedback,
    this.aiGrade,
    this.aiScorePercent,
    this.aiConfidence,
    this.aiRatingLabel,
    this.aiFeedback,
    this.aiStrengths = const [],
    this.aiImprovements = const [],
    this.aiRubric = const [],
    this.aiRiskFlags = const [],
    this.aiNextTask,
    this.aiCheckedAt,
    this.aiModel,
    this.aiProvider,
    this.aiReviewStatus,
    this.aiReviewError,
    required this.submittedAt,
    this.gradedAt,
    this.taskTitle,
    this.taskDescription,
    this.reviewMode,
    this.evaluationCriteria,
    this.studentName,
  });

  final int id;
  final int taskId;
  final int studentId;
  final String? submissionText;
  final String? imageUrl;
  final bool isGraded;
  final int? grade;
  final String? feedback;
  final int? aiGrade;
  final int? aiScorePercent;
  final int? aiConfidence;
  final String? aiRatingLabel;
  final String? aiFeedback;
  final List<String> aiStrengths;
  final List<String> aiImprovements;
  final List<AiRubricItem> aiRubric;
  final List<String> aiRiskFlags;
  final AiNextTaskSuggestion? aiNextTask;
  final DateTime? aiCheckedAt;
  final String? aiModel;
  final String? aiProvider;
  final String? aiReviewStatus;
  final String? aiReviewError;
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final String? taskTitle;
  final String? taskDescription;
  final TaskReviewMode? reviewMode;
  final String? evaluationCriteria;
  final String? studentName;

  TaskSubmission copyWith({
    int? id,
    int? taskId,
    int? studentId,
    String? submissionText,
    String? imageUrl,
    bool? isGraded,
    int? grade,
    String? feedback,
    int? aiGrade,
    int? aiScorePercent,
    int? aiConfidence,
    String? aiRatingLabel,
    String? aiFeedback,
    List<String>? aiStrengths,
    List<String>? aiImprovements,
    List<AiRubricItem>? aiRubric,
    List<String>? aiRiskFlags,
    AiNextTaskSuggestion? aiNextTask,
    DateTime? aiCheckedAt,
    String? aiModel,
    String? aiProvider,
    String? aiReviewStatus,
    String? aiReviewError,
    DateTime? submittedAt,
    DateTime? gradedAt,
    String? taskTitle,
    String? taskDescription,
    TaskReviewMode? reviewMode,
    String? evaluationCriteria,
    String? studentName,
  }) {
    return TaskSubmission(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      studentId: studentId ?? this.studentId,
      submissionText: submissionText ?? this.submissionText,
      imageUrl: imageUrl ?? this.imageUrl,
      isGraded: isGraded ?? this.isGraded,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      aiGrade: aiGrade ?? this.aiGrade,
      aiScorePercent: aiScorePercent ?? this.aiScorePercent,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiRatingLabel: aiRatingLabel ?? this.aiRatingLabel,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      aiStrengths: aiStrengths ?? this.aiStrengths,
      aiImprovements: aiImprovements ?? this.aiImprovements,
      aiRubric: aiRubric ?? this.aiRubric,
      aiRiskFlags: aiRiskFlags ?? this.aiRiskFlags,
      aiNextTask: aiNextTask ?? this.aiNextTask,
      aiCheckedAt: aiCheckedAt ?? this.aiCheckedAt,
      aiModel: aiModel ?? this.aiModel,
      aiProvider: aiProvider ?? this.aiProvider,
      aiReviewStatus: aiReviewStatus ?? this.aiReviewStatus,
      aiReviewError: aiReviewError ?? this.aiReviewError,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      taskTitle: taskTitle ?? this.taskTitle,
      taskDescription: taskDescription ?? this.taskDescription,
      reviewMode: reviewMode ?? this.reviewMode,
      evaluationCriteria: evaluationCriteria ?? this.evaluationCriteria,
      studentName: studentName ?? this.studentName,
    );
  }

  factory TaskSubmission.fromJson(Map<String, dynamic> json) {
    return TaskSubmission(
      id: json['id'] as int,
      taskId: json['task_id'] as int,
      studentId: json['student_id'] as int,
      submissionText: json['submission_text'] as String?,
      imageUrl: json['image_url'] as String?,
      isGraded: json['is_graded'] as bool? ?? false,
      grade: json['grade'] as int?,
      feedback: json['feedback'] as String?,
      aiGrade: json['ai_grade'] as int?,
      aiScorePercent: json['ai_score_percent'] as int?,
      aiConfidence: json['ai_confidence'] as int?,
      aiRatingLabel: json['ai_rating_label'] as String?,
      aiFeedback: json['ai_feedback'] as String?,
      aiStrengths: (json['ai_strengths'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
      aiImprovements: (json['ai_improvements'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
      aiRubric: (json['ai_rubric'] as List<dynamic>? ?? const [])
          .map(
            (dynamic item) =>
                AiRubricItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      aiRiskFlags: (json['ai_risk_flags'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
      aiNextTask: json['ai_next_task'] == null
          ? null
          : AiNextTaskSuggestion.fromJson(
              Map<String, dynamic>.from(json['ai_next_task'] as Map),
            ),
      aiCheckedAt: json['ai_checked_at'] == null
          ? null
          : DateTime.parse(json['ai_checked_at'] as String),
      aiModel: json['ai_model'] as String?,
      aiProvider: json['ai_provider'] as String?,
      aiReviewStatus: json['ai_review_status'] as String?,
      aiReviewError: json['ai_review_error'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      gradedAt: json['graded_at'] == null
          ? null
          : DateTime.parse(json['graded_at'] as String),
      taskTitle: json['task_title'] as String?,
      taskDescription: json['task_description'] as String?,
      reviewMode: json['review_mode'] == null
          ? null
          : TaskReviewMode.fromApiValue(json['review_mode'] as String),
      evaluationCriteria: json['evaluation_criteria'] as String?,
      studentName: json['student_name'] as String?,
    );
  }
}

class AiRubricItem {
  const AiRubricItem({
    required this.criterion,
    required this.score,
    required this.maxScore,
    this.comment,
  });

  final String criterion;
  final int score;
  final int maxScore;
  final String? comment;

  factory AiRubricItem.fromJson(Map<String, dynamic> json) {
    return AiRubricItem(
      criterion: json['criterion'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      maxScore: json['max_score'] as int? ?? 5,
      comment: json['comment'] as String?,
    );
  }
}

class AiNextTaskSuggestion {
  const AiNextTaskSuggestion({
    required this.title,
    required this.prompt,
    this.focusReason,
    required this.difficultyLevel,
    this.estimatedTimeMinutes,
  });

  final String title;
  final String prompt;
  final String? focusReason;
  final int difficultyLevel;
  final int? estimatedTimeMinutes;

  factory AiNextTaskSuggestion.fromJson(Map<String, dynamic> json) {
    return AiNextTaskSuggestion(
      title: json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      focusReason: json['focus_reason'] as String?,
      difficultyLevel: json['difficulty_level'] as int? ?? 2,
      estimatedTimeMinutes: json['estimated_time_minutes'] as int?,
    );
  }
}
