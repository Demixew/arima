import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../tasks/domain/task_item.dart';
import '../domain/linked_student.dart';
import '../domain/task_submission.dart';
import '../domain/teacher_metrics.dart';

final Provider<TeacherRepository> teacherRepositoryProvider =
    Provider<TeacherRepository>((Ref ref) {
  return TeacherRepository(ref.watch(dioProvider));
});

class TeacherRepository {
  TeacherRepository(this._dio);

  final Dio _dio;

  Future<List<LinkedStudent>> fetchLinkedStudents() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/teacher/students');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((dynamic item) => LinkedStudent.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<TaskItem> assignTask({
    required int studentId,
    required String title,
    String? description,
    DateTime? dueAt,
    bool requiresSubmission = false,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/teacher/tasks',
      queryParameters: <String, dynamic>{
        'student_id': studentId,
        'title': title,
        if (description != null) 'description': description,
        if (dueAt != null) 'due_at': dueAt.toUtc().toIso8601String(),
        'requires_submission': requiresSubmission,
      },
    );
    return TaskItem.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Map<String, dynamic>>> fetchStudentTasks(int studentId) async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/teacher/students/$studentId/tasks');
    return (response.data as List<dynamic>)
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<TaskSubmission>> fetchSubmissions() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/teacher/submissions');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((dynamic item) => TaskSubmission.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<TaskSubmission> gradeSubmission({

    required int submissionId,
    required int grade,
    String? feedback,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/teacher/submissions/$submissionId/grade',
      data: <String, dynamic>{
        'grade': grade,
        if (feedback != null) 'feedback': feedback,
      },
    );
    return TaskSubmission.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<TeacherMetrics> fetchTeacherMetrics() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/teacher/metrics');
    return TeacherMetrics.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> linkStudent(String studentEmail) async {
    await _dio.post<dynamic>(
      '/teacher/students/link',
      queryParameters: <String, dynamic>{'student_email': studentEmail},
    );
  }

  Future<void> unlinkStudent(int studentId) async {
    await _dio.delete<dynamic>('/teacher/students/$studentId/unlink');
  }
}
