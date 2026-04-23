import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/child_stats.dart';
import '../domain/linked_child.dart';

final Provider<ParentRepository> parentRepositoryProvider =
    Provider<ParentRepository>((Ref ref) {
  return ParentRepository(ref.watch(dioProvider));
});

class ParentRepository {
  ParentRepository(this._dio);

  final Dio _dio;

  Future<List<LinkedChild>> fetchLinkedChildren() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/metrics/children');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((dynamic item) => LinkedChild.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<ChildStats> fetchChildStats(int childId) async {
    final Response<dynamic> response =
        await _dio.get<dynamic>('/metrics/children/$childId/stats');
    return ChildStats.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> linkChild(String childEmail) async {
    await _dio.post<dynamic>(
      '/metrics/children/link',
      data: <String, dynamic>{'child_email': childEmail},
    );
  }

  Future<void> unlinkChild(int childId) async {
    await _dio.delete<dynamic>('/metrics/children/$childId/unlink');
  }
}
