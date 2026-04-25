import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/task_repository.dart';
import '../domain/study_plan.dart';

final AutoDisposeAsyncNotifierProvider<StudyPlanController, StudyPlan?>
    studyPlanControllerProvider =
    AutoDisposeAsyncNotifierProvider<StudyPlanController, StudyPlan?>(
  StudyPlanController.new,
);

class StudyPlanController extends AutoDisposeAsyncNotifier<StudyPlan?> {
  @override
  Future<StudyPlan?> build() async {
    return ref.read(taskRepositoryProvider).fetchStudyPlan();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(taskRepositoryProvider).fetchStudyPlan(),
    );
  }
}
