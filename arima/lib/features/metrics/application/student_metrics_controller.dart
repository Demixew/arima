import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/metrics_repository.dart';
import '../domain/user_metrics.dart';

final AutoDisposeAsyncNotifierProvider<StudentMetricsController, UserMetrics?>
    studentMetricsControllerProvider =
    AutoDisposeAsyncNotifierProvider<StudentMetricsController, UserMetrics?>(
  StudentMetricsController.new,
);

class StudentMetricsController extends AutoDisposeAsyncNotifier<UserMetrics?> {
  @override
  Future<UserMetrics?> build() async {
    try {
      return await ref.read(metricsRepositoryProvider).fetchMyMetrics();
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue<UserMetrics?>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      try {
        return await ref.read(metricsRepositoryProvider).fetchMyMetrics();
      } catch (_) {
        return null;
      }
    });
  }
}
