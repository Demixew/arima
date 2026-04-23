import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/task_status.dart';

enum TaskFilter {
  all,
  active,
  completed,
  overdue;

  String get label {
    switch (this) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.active:
        return 'Active';
      case TaskFilter.completed:
        return 'Completed';
      case TaskFilter.overdue:
        return 'Overdue';
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
