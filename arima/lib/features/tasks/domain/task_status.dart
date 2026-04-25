import '../../../core/l10n/app_localizations.dart';

enum TaskStatus {
  pending,
  inProgress,
  completed,
  overdue;

  String get apiValue {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.overdue:
        return 'overdue';
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case TaskStatus.pending:
        return l10n.statusPending;
      case TaskStatus.inProgress:
        return l10n.statusInProgress;
      case TaskStatus.completed:
        return l10n.statusCompleted;
      case TaskStatus.overdue:
        return l10n.statusOverdue;
    }
  }

  static TaskStatus fromApiValue(String value) {
    return switch (value) {
      'pending' => TaskStatus.pending,
      'in_progress' => TaskStatus.inProgress,
      'completed' => TaskStatus.completed,
      'overdue' => TaskStatus.overdue,
      _ => TaskStatus.pending,
    };
  }
}
