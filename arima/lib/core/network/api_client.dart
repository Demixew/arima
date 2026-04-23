import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_session.dart';
import 'api_config.dart';
import 'api_exception.dart';

final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: <String, String>{'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        final AuthSession? session = ref.read(authControllerProvider).valueOrNull;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
      onError: (DioException error, ErrorInterceptorHandler handler) {
        handler.reject(error);
      },
    ),
  );

  return dio;
});

ApiException mapDioException(DioException error) {
  final Object? data = error.response?.data;
  if (data is Map<String, dynamic> && data['detail'] is String) {
    return ApiException(data['detail'] as String);
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return const ApiException('Connection to backend timed out.');
  }

  if (error.type == DioExceptionType.connectionError) {
    return const ApiException('Cannot reach backend API. Check if FastAPI is running.');
  }

  return ApiException(error.message ?? 'Unexpected network error.');
}
