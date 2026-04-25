import '../../../core/l10n/app_localizations.dart';

enum TaskReviewMode {
  teacherOnly,
  teacherAndAi,
  aiOnly;

  String get apiValue {
    switch (this) {
      case TaskReviewMode.teacherOnly:
        return 'teacher_only';
      case TaskReviewMode.teacherAndAi:
        return 'teacher_and_ai';
      case TaskReviewMode.aiOnly:
        return 'ai_only';
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case TaskReviewMode.teacherOnly:
        return l10n.reviewModeTeacherOnly;
      case TaskReviewMode.teacherAndAi:
        return l10n.reviewModeTeacherAndAi;
      case TaskReviewMode.aiOnly:
        return l10n.reviewModeAiOnly;
    }
  }

  static TaskReviewMode fromApiValue(String value) {
    switch (value) {
      case 'teacher_and_ai':
        return TaskReviewMode.teacherAndAi;
      case 'ai_only':
        return TaskReviewMode.aiOnly;
      case 'teacher_only':
      default:
        return TaskReviewMode.teacherOnly;
    }
  }
}
