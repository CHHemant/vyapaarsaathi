// frontend/lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/local_auth_service.dart';

final authServiceProvider = Provider<LocalAuthService>((ref) {
  return LocalAuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final authService = ref.watch(authServiceProvider);
  await authService.initialize();

  // Emit initial state
  yield await _buildAuthState(authService);

  // Listen for changes (in real app, use StreamController)
});

final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.isLoggedIn ?? false;
});

Future<AuthState> _buildAuthState(LocalAuthService authService) async {
  final currentUser = await authService.getCurrentUser();
  return AuthState(
    isLoggedIn: currentUser != null && currentUser.isActive,
    user: currentUser,
    isLoading: false,
  );
}

class AuthState {
  final bool isLoggedIn;
  final UserProfile? user;
  final bool isLoading;

  const AuthState({
    required this.isLoggedIn,
    this.user,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserProfile? user,
    bool? isLoading,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
