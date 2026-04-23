import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_session.dart';

final Provider<RouterRefreshNotifier> routerRefreshNotifierProvider =
    Provider<RouterRefreshNotifier>((Ref ref) {
  final RouterRefreshNotifier notifier = RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    _subscription = _ref.listen<AsyncValue<AuthSession?>>(
      authControllerProvider,
      (AsyncValue<AuthSession?>? previous, AsyncValue<AuthSession?> next) {
        notifyListeners();
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;
  ProviderSubscription<AsyncValue<AuthSession?>>? _subscription;

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}
