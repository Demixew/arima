import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/teacher_repository.dart';
import '../domain/linked_student.dart';
import '../domain/task_submission.dart';
import '../domain/teacher_metrics.dart';

final AsyncNotifierProvider<TeacherController, TeacherState> teacherControllerProvider =
    AsyncNotifierProvider<TeacherController, TeacherState>(TeacherController.new);

class TeacherState {
  const TeacherState({
    this.students = const [],
    this.metrics,
    this.selectedStudentId,
    this.studentTasks = const [],
    this.pendingSubmissions = const [],
  });

  final List<LinkedStudent> students;
  final TeacherMetrics? metrics;
  final int? selectedStudentId;
  final List<Map<String, dynamic>> studentTasks;
  final List<TaskSubmission> pendingSubmissions;

  TeacherState copyWith({
    List<LinkedStudent>? students,
    TeacherMetrics? metrics,
    int? selectedStudentId,
    List<Map<String, dynamic>>? studentTasks,
    List<TaskSubmission>? pendingSubmissions,

  }) {
    return TeacherState(
      students: students ?? this.students,
      metrics: metrics ?? this.metrics,
      selectedStudentId: selectedStudentId ?? this.selectedStudentId,
      studentTasks: studentTasks ?? this.studentTasks,
      pendingSubmissions: pendingSubmissions ?? this.pendingSubmissions,
    );
  }
}

class TeacherController extends AsyncNotifier<TeacherState> {
  @override
  Future<TeacherState> build() async {
    final students = await ref.read(teacherRepositoryProvider).fetchLinkedStudents();
    final metrics = await ref.read(teacherRepositoryProvider).fetchTeacherMetrics();
    final submissions = await ref.read(teacherRepositoryProvider).fetchSubmissions();
    return TeacherState(
      students: students,
      metrics: metrics,
      pendingSubmissions: submissions,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final students = await ref.read(teacherRepositoryProvider).fetchLinkedStudents();
      final metrics = await ref.read(teacherRepositoryProvider).fetchTeacherMetrics();
      final submissions = await ref.read(teacherRepositoryProvider).fetchSubmissions();
      return TeacherState(
        students: students,
        metrics: metrics,
        pendingSubmissions: submissions,
      );
    });
  }

  Future<void> loadStudentTasks(int studentId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final tasks = await ref.read(teacherRepositoryProvider).fetchStudentTasks(studentId);
    state = AsyncValue.data(current.copyWith(
      selectedStudentId: studentId,
      studentTasks: tasks,
    ));
  }

  Future<void> assignTask({
    required int studentId,
    required String title,
    String? description,
    DateTime? dueAt,
    bool requiresSubmission = false,
  }) async {
    await ref.read(teacherRepositoryProvider).assignTask(
      studentId: studentId,
      title: title,
      description: description,
      dueAt: dueAt,
      requiresSubmission: requiresSubmission,
    );
    await refresh();
  }

  Future<void> gradeSubmission({
    required int submissionId,
    required int grade,
    String? feedback,
  }) async {
    await ref.read(teacherRepositoryProvider).gradeSubmission(
      submissionId: submissionId,
      grade: grade,
      feedback: feedback,
    );
    await refresh();
  }

  Future<void> linkStudent(String email) async {
    await ref.read(teacherRepositoryProvider).linkStudent(email);
    await refresh();
  }

  Future<void> unlinkStudent(int studentId) async {
    await ref.read(teacherRepositoryProvider).unlinkStudent(studentId);
    await refresh();
  }
}
