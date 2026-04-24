import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../domain/task_status.dart';

enum TaskFilter {
  all,
  active,
  completed,
  overdue;

  String label(AppLocalizations l10n) {
    switch (this) {
      case TaskFilter.all:
        return l10n.filterAll;
      case TaskFilter.active:
        return l10n.filterActive;
      case TaskFilter.completed:
        return l10n.completed;
      case TaskFilter.overdue:
        return l10n.overdue;
    }
  }
}

final NotifierProvider<TaskViewController, TaskFilter> taskViewControllerProvider =
    NotifierProvider<TaskViewController, TaskFilter>(TaskViewController.new);

class TaskViewController extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => TaskFilter.all;

  void setFilter(TaskFilter filter) {
    state = filter;
  }

  bool matches(TaskStatus status) {
    return switch (state) {
      TaskFilter.all => true,
      TaskFilter.active => status == TaskStatus.pending || status == TaskStatus.inProgress,
      TaskFilter.completed => status == TaskStatus.completed,
      TaskFilter.overdue => status == TaskStatus.overdue,
    };
  }
}
