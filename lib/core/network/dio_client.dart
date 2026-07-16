import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/core/storage/token_storage.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DioClient {
  static Dio create(TokenStorage tokenStorage, Ref ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {"accept": "application/json"},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getToken(); 

          final skipAuth = options.extra['skipAuth'] == true;

          if (!skipAuth && token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }

          handler.next(options);
        },

        onError: (error, handler) async {
          if (error.response?.statusCode == 401) { 
              
            await tokenStorage.clearToken(); 
            await ref.read(authProvider.notifier).tokenExpired();
          }

          handler.next(error);
        },
      ),
    );
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

    return dio;
  }
}
