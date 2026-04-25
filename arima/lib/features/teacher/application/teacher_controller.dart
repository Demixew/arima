import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/teacher_repository.dart';
import '../domain/ai_status.dart';
import '../domain/linked_student.dart';
import '../domain/task_submission.dart';
import '../domain/teacher_metrics.dart';
import '../../tasks/domain/task_review_mode.dart';

final AsyncNotifierProvider<TeacherController, TeacherState> teacherControllerProvider =
    AsyncNotifierProvider<TeacherController, TeacherState>(TeacherController.new);

class TeacherState {
  const TeacherState({
    this.students = const [],
    this.metrics,
    this.aiStatus,
    this.selectedStudentId,
    this.studentTasks = const [],
    this.pendingSubmissions = const [],
  });

  final List<LinkedStudent> students;
  final TeacherMetrics? metrics;
  final AiStatus? aiStatus;
  final int? selectedStudentId;
  final List<Map<String, dynamic>> studentTasks;
  final List<TaskSubmission> pendingSubmissions;

  TeacherState copyWith({
    List<LinkedStudent>? students,
    TeacherMetrics? metrics,
    AiStatus? aiStatus,
    int? selectedStudentId,
    List<Map<String, dynamic>>? studentTasks,
    List<TaskSubmission>? pendingSubmissions,

  }) {
    return TeacherState(
      students: students ?? this.students,
      metrics: metrics ?? this.metrics,
      aiStatus: aiStatus ?? this.aiStatus,
      selectedStudentId: selectedStudentId ?? this.selectedStudentId,
      studentTasks: studentTasks ?? this.studentTasks,
      pendingSubmissions: pendingSubmissions ?? this.pendingSubmissions,
    );
  }
}

class TeacherController extends AsyncNotifier<TeacherState> {
  TeacherState _replaceSubmission(
    TeacherState current,
    TaskSubmission updatedSubmission,
  ) {
    final updatedPending = current.pendingSubmissions
        .map(
          (submission) => submission.id == updatedSubmission.id
              ? updatedSubmission
              : submission,
        )
        .toList();

    return current.copyWith(pendingSubmissions: updatedPending);
  }

  Future<void> _syncTeacherOverview() async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final repository = ref.read(teacherRepositoryProvider);
    final results = await Future.wait<dynamic>([
      repository.fetchLinkedStudents(),
      repository.fetchTeacherMetrics(),
      repository.fetchSubmissions(),
      _loadAiStatusSafely(),
    ]);

    state = AsyncValue.data(
      current.copyWith(
        students: results[0] as List<LinkedStudent>,
        metrics: results[1] as TeacherMetrics,
        pendingSubmissions: results[2] as List<TaskSubmission>,
        aiStatus: results[3] as AiStatus?,
      ),
    );
  }

  Future<AiStatus?> _loadAiStatusSafely() async {
    try {
      return await ref.read(teacherRepositoryProvider).fetchAiStatus();
    } catch (_) {
      return AiStatus.unavailable(
        'AI status could not be loaded. The app can keep working without it.',
      );
    }
  }

  @override
  Future<TeacherState> build() async {
    final repository = ref.read(teacherRepositoryProvider);
    final results = await Future.wait<dynamic>([
      repository.fetchLinkedStudents(),
      repository.fetchTeacherMetrics(),
      repository.fetchSubmissions(),
      _loadAiStatusSafely(),
    ]);
    return TeacherState(
      students: results[0] as List<LinkedStudent>,
      metrics: results[1] as TeacherMetrics,
      pendingSubmissions: results[2] as List<TaskSubmission>,
      aiStatus: results[3] as AiStatus?,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(teacherRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repository.fetchLinkedStudents(),
        repository.fetchTeacherMetrics(),
        repository.fetchSubmissions(),
        _loadAiStatusSafely(),
      ]);
      return TeacherState(
        students: results[0] as List<LinkedStudent>,
        metrics: results[1] as TeacherMetrics,
        pendingSubmissions: results[2] as List<TaskSubmission>,
        aiStatus: results[3] as AiStatus?,
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
    int difficultyLevel = 2,
    int? estimatedTimeMinutes,
    bool antiFatigueEnabled = false,
    bool isChallenge = false,
    String? challengeTitle,
    String? challengeCategory,
    int challengeBonusXp = 0,
    TaskReviewMode reviewMode = TaskReviewMode.teacherOnly,
    String? evaluationCriteria,
  }) async {
    await ref.read(teacherRepositoryProvider).assignTask(
      studentId: studentId,
      title: title,
      description: description,
      dueAt: dueAt,
      requiresSubmission: requiresSubmission,
      difficultyLevel: difficultyLevel,
      estimatedTimeMinutes: estimatedTimeMinutes,
      antiFatigueEnabled: antiFatigueEnabled,
      isChallenge: isChallenge,
      challengeTitle: challengeTitle,
      challengeCategory: challengeCategory,
      challengeBonusXp: challengeBonusXp,
      reviewMode: reviewMode,
      evaluationCriteria: evaluationCriteria,
    );
    await refresh();
  }

  Future<void> gradeSubmission({
    required int submissionId,
    required int grade,
    String? feedback,
  }) async {
    final current = state.valueOrNull;
    final updatedSubmission = await ref.read(teacherRepositoryProvider).gradeSubmission(
      submissionId: submissionId,
      grade: grade,
      feedback: feedback,
    );
    if (current != null) {
      state = AsyncValue.data(_replaceSubmission(current, updatedSubmission));
    }
    await _syncTeacherOverview();
  }

  Future<void> linkStudent(String email) async {
    await ref.read(teacherRepositoryProvider).linkStudent(email);
    await refresh();
  }

  Future<void> unlinkStudent(int studentId) async {
    await ref.read(teacherRepositoryProvider).unlinkStudent(studentId);
    await refresh();
  }

  Future<void> runAiReview(int submissionId) async {
    final current = state.valueOrNull;
    if (current != null) {
      final pendingSubmissions = current.pendingSubmissions
          .map(
            (submission) => submission.id == submissionId
                ? submission.copyWith(
                    aiReviewStatus: 'pending',
                    aiReviewError: null,
                  )
                : submission,
          )
          .toList();
      state = AsyncValue.data(
        current.copyWith(pendingSubmissions: pendingSubmissions),
      );
    }

    try {
      final updatedSubmission =
          await ref.read(teacherRepositoryProvider).runAiReview(submissionId);
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncValue.data(_replaceSubmission(latest, updatedSubmission));
      }
    } catch (_) {
      await _syncTeacherOverview();
      rethrow;
    }

    await _syncTeacherOverview();
  }

  Future<void> assignAiNextTask(int submissionId) async {
    await ref.read(teacherRepositoryProvider).assignAiNextTask(submissionId);
    await _syncTeacherOverview();
  }

  Future<void> extendTaskDeadline({
    required int taskId,
    required DateTime dueAt,
  }) async {
    await ref.read(teacherRepositoryProvider).extendTaskDeadline(
          taskId: taskId,
          dueAt: dueAt,
        );
    await _syncTeacherOverview();
    final selectedStudentId = state.valueOrNull?.selectedStudentId;
    if (selectedStudentId != null) {
      await loadStudentTasks(selectedStudentId);
    }
  }
}
