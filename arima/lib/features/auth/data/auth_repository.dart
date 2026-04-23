import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../domain/auth_session.dart';

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
  );
});

class AuthRepository {
  AuthRepository({required Dio dio}) : _dio = dio;

  static const String sessionStorageKey = 'auth_session';

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/login',
        data: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );

      final Map<String, dynamic> tokenJson = Map<String, dynamic>.from(response.data as Map);
      final Response<dynamic> userResponse = await _dio.get<dynamic>(
        '/auth/me',
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer ${tokenJson['access_token']}',
          },
        ),
      );

      return AuthSession.fromJson(<String, dynamic>{
        ...tokenJson,
        'user': userResponse.data,
      });
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<AuthSession> register({
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/register',
        data: <String, dynamic>{
          'email': email,
          'full_name': fullName,
          'password': password,
          'role': role,
        },
      );

      return AuthSession.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<AuthSession?> restoreSession() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(sessionStorageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final AuthSession storedSession = AuthSession.fromJson(json);

      final Response<dynamic> userResponse = await _dio.get<dynamic>(
        '/auth/me',
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer ${storedSession.accessToken}',
          },
        ),
      );

      final AuthSession restoredSession = AuthSession.fromJson(<String, dynamic>{
        'access_token': storedSession.accessToken,
        'token_type': storedSession.tokenType,
        'user': userResponse.data,
      });

      await persistSession(restoredSession);
      return restoredSession;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> persistSession(AuthSession session) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(sessionStorageKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(sessionStorageKey);
  }
}
