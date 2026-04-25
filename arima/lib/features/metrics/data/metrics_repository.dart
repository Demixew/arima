import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_metrics.dart';

final Provider<MetricsRepository> metricsRepositoryProvider =
    Provider<MetricsRepository>((Ref ref) {
  return MetricsRepository(ref.watch(dioProvider));
});

class MetricsRepository {
  MetricsRepository(this._dio);

  final Dio _dio;

  Future<UserMetrics> fetchMyMetrics() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/metrics/me');
    return UserMetrics.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
