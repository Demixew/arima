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

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.overdue:
        return 'Overdue';
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
