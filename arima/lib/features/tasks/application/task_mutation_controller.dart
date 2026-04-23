import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/task_repository.dart';
import '../domain/task_status.dart';
import 'task_list_controller.dart';

final AutoDisposeAsyncNotifierProvider<TaskMutationController, void> taskMutationControllerProvider =
    AutoDisposeAsyncNotifierProvider<TaskMutationController, void>(TaskMutationController.new);

class TaskMutationController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createTask({
    required String title,
    String? description,
    required TaskStatus status,
    DateTime? dueAt,
    required bool reminderEnabled,
    required int remindAfterHours,
    required int maxMissedCount,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).createTask(
            title: title,
            description: description,
            status: status,
            dueAt: dueAt,
            reminderEnabled: reminderEnabled,
            remindAfterHours: remindAfterHours,
            maxMissedCount: maxMissedCount,
          );
      await ref.read(taskListControllerProvider.notifier).refresh();
    });
  }

  Future<void> updateTask({
    required int id,
    required String title,
    String? description,
    required TaskStatus status,
    DateTime? dueAt,
    required bool reminderEnabled,
    required int remindAfterHours,
    required int maxMissedCount,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).updateTask(
            id: id,
            title: title,
            description: description,
            status: status,
            dueAt: dueAt,
            reminderEnabled: reminderEnabled,
            remindAfterHours: remindAfterHours,
            maxMissedCount: maxMissedCount,
          );
      await ref.read(taskListControllerProvider.notifier).refresh();
    });
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).deleteTask(id);
      await ref.read(taskListControllerProvider.notifier).refresh();
    });
  }

  String? errorMessage() {
    return state.whenOrNull(
      error: (Object error, StackTrace stackTrace) {
        if (error is ApiException) {
          return error.message;
        }
        return 'Task update failed.';
      },
    );
  }
}
