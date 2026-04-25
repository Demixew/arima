import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../metrics/application/student_metrics_controller.dart';
import '../data/task_repository.dart';
import '../domain/task_status.dart';
import 'study_plan_controller.dart';
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
    required int difficultyLevel,
    required int? estimatedTimeMinutes,
    required bool antiFatigueEnabled,
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
            difficultyLevel: difficultyLevel,
            estimatedTimeMinutes: estimatedTimeMinutes,
            antiFatigueEnabled: antiFatigueEnabled,
          );
      await ref.read(taskListControllerProvider.notifier).refresh();
      await ref.read(studentMetricsControllerProvider.notifier).refresh();
      await ref.read(studyPlanControllerProvider.notifier).refresh();
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
    required int difficultyLevel,
    required int? estimatedTimeMinutes,
    required bool antiFatigueEnabled,
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
            difficultyLevel: difficultyLevel,
            estimatedTimeMinutes: estimatedTimeMinutes,
            antiFatigueEnabled: antiFatigueEnabled,
          );
      await ref.read(taskListControllerProvider.notifier).refresh();
      await ref.read(studentMetricsControllerProvider.notifier).refresh();
      await ref.read(studyPlanControllerProvider.notifier).refresh();
    });
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).deleteTask(id);
      await ref.read(taskListControllerProvider.notifier).refresh();
      await ref.read(studentMetricsControllerProvider.notifier).refresh();
      await ref.read(studyPlanControllerProvider.notifier).refresh();
    });
  }

  Future<void> submitTask({
    required int taskId,
    required String submissionText,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).submitTask(
            taskId: taskId,
            submissionText: submissionText,
          );
      await ref.read(taskListControllerProvider.notifier).refresh();
      await ref.read(studentMetricsControllerProvider.notifier).refresh();
      await ref.read(studyPlanControllerProvider.notifier).refresh();
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
