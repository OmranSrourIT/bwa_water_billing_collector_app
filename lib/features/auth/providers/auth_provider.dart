import 'package:bwa_water_billing_collector_app/core/storage/token_storage.dart';
import 'package:bwa_water_billing_collector_app/features/Account/provider/account_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/models/auth_model.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/ForgotPasswordApiService.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/forgot_password_service.dart';
import 'package:bwa_water_billing_collector_app/features/batch/providers/batch_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoice_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bwa_water_billing_collector_app/core/network/dio_client.dart';

import 'package:bwa_water_billing_collector_app/features/auth/services/AuthService.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/auth_state.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/auth_api_service.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final dioProvider = Provider((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider); // استخدم watch
  return DioClient.create(tokenStorage, ref);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.read(dioProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  return AuthApiService(dio, tokenStorage);
});

final forgotPasswordProvider = Provider<ForgotPasswordService>((ref) {
  final dio = ref.read(dioProvider);
  return ForgotPasswordApiService(dio);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.read(authServiceProvider);
  final tokenStorage = ref.read(tokenStorageProvider);

  return AuthNotifier(service, tokenStorage, ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService service;
  final TokenStorage tokenStorage;
  final Ref ref;

  AuthNotifier(this.service, this.tokenStorage, this.ref)
    : super(const AuthState()) {
    checkToken();
  }

  Future<void> checkToken() async {
    final token = await tokenStorage.getToken();

    if (token != null && token.isNotEmpty) {
      state = AuthState(
        user: AuthUser(token: token),
        successLogin: true,
        initialized: true,
      );
    } else {
      state = const AuthState(initialized: true);
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successLogin: false);

    try {
      final user = await service.login(username: username, password: password);

      state = AuthState(
        isLoading: false,
        user: user,
        error: null,
        successLogin: true, // 👈 IMPORTANT
        initialized: true,
      );

      // 🔥 أهم خطوة: عمل invalidate للـ dio لكي يحصل على التوكن الجديد
      ref.invalidate(dioProvider);

      // بعدها عمل invalidate للبيانات الأخرى
      ref.invalidate(accountProvider);
      ref.invalidate(batchProvider);
      ref.invalidate(invoicesProvider);
    } catch (e) {
      state = AuthState(
        isLoading: false,
        user: null,
        error: e.toString(),
        successLogin: false,
      );
    }
  }

  Future<void> logout() async {
    await service.logout();
    await tokenStorage.clearToken();  
    
    state = const AuthState(
      initialized: true,
      user: null,
      successLogin: false,
      tokenExpired: false,
      error: null
    );
    ref.invalidate(dioProvider);
  }

  Future<void> tokenExpired() async {
    await tokenStorage.clearToken();
 
    state = const AuthState(
      initialized: true,
      user: null,
      successLogin: false,
      tokenExpired: true,
    );
    ref.invalidate(dioProvider);
  }
}
