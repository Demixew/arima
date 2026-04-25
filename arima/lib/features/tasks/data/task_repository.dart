import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/study_plan.dart';
import '../domain/task_item.dart';
import '../domain/task_status.dart';

final Provider<TaskRepository> taskRepositoryProvider =
    Provider<TaskRepository>((Ref ref) {
  return TaskRepository(ref.watch(dioProvider));
});

class TaskRepository {
  TaskRepository(this._dio);

  final Dio _dio;

  Future<List<TaskItem>> fetchTasks() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/tasks');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) => TaskItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<StudyPlan> fetchStudyPlan() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/tasks/study-plan');
      return StudyPlan.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<TaskItem> createTask({
    required String title,
    String? description,
    required TaskStatus status,
    DateTime? dueAt,
    bool reminderEnabled = true,
    int remindAfterHours = 6,
    int maxMissedCount = 3,
    int difficultyLevel = 2,
    int? estimatedTimeMinutes,
    bool antiFatigueEnabled = false,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/tasks',
        data: <String, dynamic>{
          'title': title,
          'description': description,
          'status': status.apiValue,
          'due_at': dueAt?.toUtc().toIso8601String(),
          'difficulty_level': difficultyLevel,
          if (estimatedTimeMinutes != null)
            'estimated_time_minutes': estimatedTimeMinutes,
          'anti_fatigue_enabled': antiFatigueEnabled,
          'reminder': <String, dynamic>{
            'is_enabled': reminderEnabled,
            'remind_after_hours': remindAfterHours,
            'max_missed_count': maxMissedCount,
          },
        },
      );
      return TaskItem.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<TaskItem> updateTask({
    required int id,
    required String title,
    String? description,
    required TaskStatus status,
    DateTime? dueAt,
    required bool reminderEnabled,
    required int remindAfterHours,
    required int maxMissedCount,
    int difficultyLevel = 2,
    int? estimatedTimeMinutes,
    bool antiFatigueEnabled = false,
  }) async {
    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        '/tasks/$id',
        data: <String, dynamic>{
          'title': title,
          'description': description,
          'status': status.apiValue,
          'due_at': dueAt?.toUtc().toIso8601String(),
          'difficulty_level': difficultyLevel,
          if (estimatedTimeMinutes != null)
            'estimated_time_minutes': estimatedTimeMinutes,
          'anti_fatigue_enabled': antiFatigueEnabled,
          'reminder': <String, dynamic>{
            'is_enabled': reminderEnabled,
            'remind_after_hours': remindAfterHours,
            'max_missed_count': maxMissedCount,
          },
        },
      );
      return TaskItem.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete<dynamic>('/tasks/$id');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<void> submitTask({
    required int taskId,
    required String submissionText,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/teacher/tasks/$taskId/submit',
        data: <String, dynamic>{
          'submission_text': submissionText,
        },
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
