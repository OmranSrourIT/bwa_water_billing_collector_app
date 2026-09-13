import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/core/storage/token_storage.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DioClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  final Ref ref;

  bool _sessionExpiredHandled = false;

  DioClient._({
    required this.dio,
    required this.tokenStorage,
    required this.ref,
  });

  static DioClient create(TokenStorage tokenStorage, Ref ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {"accept": "application/json"},
      ),
    );

    final client = DioClient._(dio: dio, tokenStorage: tokenStorage, ref: ref);

    client._addInterceptors();

    return client;
  }

  void _addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;

          if (skipAuth) {
            handler.next(options);
            return;
          }

          final tokenBefore = await tokenStorage.getToken();

          if (tokenBefore == null || tokenBefore.isEmpty) {
            handler.next(options);
            return;
          }

          /*
   * نقرأ مرة ثانية بعد القراءة الأولى.
   * هذا يمنع إرسال الطلب إذا تغير التوكن أثناء تجهيز الطلب.
   */
          final tokenAfter = await tokenStorage.getToken();

          if (tokenBefore != tokenAfter) {
            print('[CANCEL OLD REQUEST] token changed before request was sent');

            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'Request cancelled because token changed',
              ),
              true,
            );
          }

          options.extra['requestToken'] = tokenAfter;
          options.headers['Authorization'] = 'Bearer $tokenAfter';

          print(
            '[REQUEST] ${options.method} ${options.uri} '
            'tokenHash=${tokenAfter.hashCode}',
          );

          handler.next(options);
        },

       onError: (error, handler) async {
  final statusCode = error.response?.statusCode;
  final requestOptions = error.requestOptions;

  final skipAuth = requestOptions.extra['skipAuth'] == true;

  if (statusCode == 401 && !skipAuth) {
    final failedToken =
        requestOptions.extra['requestToken'] as String?;

    final currentToken = await tokenStorage.getToken();

    debugPrint(
      '[401] '
      'failedTokenHash=${failedToken?.hashCode}, '
      'currentTokenHash=${currentToken?.hashCode}, '
      'same=${failedToken == currentToken}',
    );

    /*
     * إذا كان الطلب خرج بالتوكن القديم، لا تغيّر حالة الجلسة
     * ولا تمسح التوكن الجديد.
     */
    if (failedToken == null || failedToken != currentToken) {
      handler.next(error);
      return;
    }

    await ref
        .read(authProvider.notifier)
        .tokenExpired(failedToken: failedToken);
  }

  handler.next(error);
},

      ),
    );

    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  void resetSessionGuard() {
    _sessionExpiredHandled = false;
  }

 
}
