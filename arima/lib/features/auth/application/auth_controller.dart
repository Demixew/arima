import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

final AsyncNotifierProvider<AuthController, AuthSession?> authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final AuthSession session = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      await ref.read(authRepositoryProvider).persistSession(session);
      return session;
    });
  }

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final AuthSession session = await ref.read(authRepositoryProvider).register(
            email: email,
            fullName: fullName,
            password: password,
            role: role,
          );
      await ref.read(authRepositoryProvider).persistSession(session);
      return session;
    });
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).clearSession();
    state = const AsyncValue.data(null);
  }

  String? errorMessage() {
    return state.whenOrNull(
      error: (Object error, StackTrace stackTrace) {
        if (error is ApiException) {
          return error.message;
        }
        return 'Authentication failed.';
      },
    );
  }
}
