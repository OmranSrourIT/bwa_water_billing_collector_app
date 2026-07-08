import 'package:bwa_water_billing_collector_app/features/auth/models/auth_model.dart';

class AuthState {
  final bool isLoading;
  final AuthUser? user;
  final String? error;
  final bool successLogin;
  final bool initialized;
    final bool tokenExpired; // 👈 جديد

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.successLogin = false,
    this.initialized = false,
        this.tokenExpired = false,
  });

  AuthState copyWith({
    bool? isLoading,
    AuthUser? user,
    String? error,
    bool? successLogin,
    bool? initialized,
    bool clearUser = false,
    bool? tokenExpired,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: error,
      successLogin: successLogin ?? this.successLogin,
      initialized: initialized ?? this.initialized,
      tokenExpired: tokenExpired ?? this.tokenExpired,
    );
  }
}
