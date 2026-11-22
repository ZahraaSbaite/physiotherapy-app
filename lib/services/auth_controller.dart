import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';
import 'providers.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

enum AuthStatus {
  unknown, // checking the saved token at app start
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.restoreError,
  });

  final AuthStatus status;
  final AppUser? user;

  /// Set when the app could not check the saved login (for example no internet).
  final String? restoreError;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // A logged-in request got a 401 (token expired or account deactivated)
    final api = ref.read(apiClientProvider);
    api.onUnauthorized = _expire;
    ref.onDispose(() => api.onUnauthorized = null);

    Future.microtask(restore);
    return const AuthState(status: AuthStatus.unknown);
  }

  /// Runs at app start: is the saved token still valid?
  Future<void> restore() async {
    state = const AuthState(status: AuthStatus.unknown);
    try {
      final user =
          await ref.read(authRepositoryProvider).currentUser();
      state =
          user == null
              ? const AuthState(status: AuthStatus.unauthenticated)
              : AuthState(
                status: AuthStatus.authenticated,
                user: user,
              );
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await ref.read(tokenStorageProvider).clear();
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        // No internet or server down: keep the saved login, let the user retry
        state = AuthState(
          status: AuthStatus.unknown,
          restoreError: e.message,
        );
      }
    }
  }

  /// Throws an ApiException with a readable message if the login fails.
  Future<void> login(String email, String password) async {
    final user = await ref
        .read(authRepositoryProvider)
        .login(email, password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// Registers a new therapist account and signs them in.
  /// Throws an ApiException with a readable message if registration fails.
  Future<void> registerTherapist({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .registerTherapist(
          fullName: fullName,
          email: email,
          password: password,
        );
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// After the user edits their profile.
  void setUser(AppUser user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> _expire() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
