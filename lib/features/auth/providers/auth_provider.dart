import 'package:bwa_water_billing_collector_app/core/storage/token_storage.dart';
import 'package:bwa_water_billing_collector_app/features/Account/provider/account_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/models/auth_model.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/ForgotPasswordApiService.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/forgot_password_service.dart';
import 'package:bwa_water_billing_collector_app/features/batch/providers/batch_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/field_failure_lookup_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoice_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bwa_water_billing_collector_app/core/network/dio_client.dart';

import 'package:bwa_water_billing_collector_app/features/auth/services/AuthService.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/auth_state.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/auth_api_service.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  return DioClient.create(tokenStorage, ref);
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  return AuthApiService(dio, tokenStorage);
});

final forgotPasswordProvider = Provider<ForgotPasswordService>((ref) {
  final dio = ref.watch(dioProvider);
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
  bool _isExpiringToken = false;

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
      return;
    }

    state = const AuthState(initialized: true);
  }

  Future<void> login({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      successLogin: false,
      tokenExpired: false,
    );

    try {
      final user = await service.login(username: username, password: password);

      final newToken = await tokenStorage.getToken();

      if (newToken == null || newToken.trim().isEmpty) {
        throw Exception('لم يتم حفظ التوكن الجديد');
      }

      print('[LOGIN SUCCESS] newTokenHash: ${newToken.hashCode}');

      state = AuthState(
        isLoading: false,
        user: AuthUser(token: newToken),
        error: null,
        successLogin: true,
        initialized: true,
        tokenExpired: false,
      );

      if (rememberMe) {
        await tokenStorage.saveRememberMe(true);
        await tokenStorage.saveUsername(username);
        await tokenStorage.savePassword(password);
      } else {
        await tokenStorage.clearRememberMe();
        await tokenStorage.saveUsername('');
        await tokenStorage.savePassword('');
      }

      /*
     * التخلص من نتائج الطلبات القديمة.
     */
     ref.invalidate(fieldFailureLookupProvider);
    ref.invalidate(invoiceDetailProvider);
      ref.invalidate(accountProvider);
      ref.invalidate(batchProvider);
      ref.invalidate(invoicesProvider);
 
      
    } catch (e) {
      state = AuthState(
        isLoading: false,
        user: null,
        error: e.toString(),
        successLogin: false,
        initialized: true,
        tokenExpired: false,
      );
    }
  }

  Future<void> logout() async {
    final remember = await tokenStorage.getRememberMe();

    await service.logout();
    await tokenStorage.clearToken();

    if (!remember) {
      await tokenStorage.clearRememberMe();
      await tokenStorage.saveUsername("");
      await tokenStorage.savePassword("");
    }

    state = const AuthState(
      initialized: true,
      user: null,
      successLogin: false,
      tokenExpired: false,
      error: null,
    );
    
  }

 Future<void> tokenExpired({
  required String failedToken,
}) async {
  final currentToken = await tokenStorage.getToken();

  if (currentToken != failedToken) {
    return;
  }

  await tokenStorage.clearToken();

  ref.invalidate(batchProvider);
  ref.invalidate(accountProvider);
  ref.invalidate(invoicesProvider);

  state = const AuthState(
    initialized: true,
    user: null,
    successLogin: false,
    tokenExpired: true,
    error: null,
  );
}

}
