import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/task_repository.dart';
import '../domain/task_item.dart';

final AutoDisposeAsyncNotifierProvider<TaskListController, List<TaskItem>> taskListControllerProvider =
    AutoDisposeAsyncNotifierProvider<TaskListController, List<TaskItem>>(TaskListController.new);

class TaskListController extends AutoDisposeAsyncNotifier<List<TaskItem>> {
  @override
  Future<List<TaskItem>> build() async {
    return ref.read(taskRepositoryProvider).fetchTasks();
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<TaskItem>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      return ref.read(taskRepositoryProvider).fetchTasks();
    });
  }

  String? errorMessage() {
    return state.whenOrNull(
      error: (Object error, StackTrace stackTrace) {
        if (error is ApiException) {
          return error.message;
        }
        return 'Task request failed.';
      },
    );
  }
}
