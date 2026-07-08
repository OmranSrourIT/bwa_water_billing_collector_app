import 'dart:convert';
import 'package:bwa_water_billing_collector_app/core/widgets/HandelError.dart';
import 'package:dio/dio.dart';
import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/core/storage/token_storage.dart';
import 'package:bwa_water_billing_collector_app/features/auth/models/auth_model.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/AuthService.dart';

class AuthApiService implements AuthService {
  final Dio dio;
  final TokenStorage tokenStorage;

  AuthApiService(this.dio, this.tokenStorage);

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.authToken,
        options: Options(
          responseType: ResponseType.plain,
          extra: {"skipAuth": true ,"context": null}, // 👈 أهم سطر
          headers: {
            "accept": "application/json",
            "Authorization": "Basic ${_basicAuth(username, password)}",
          },
        ),
      );

      final data = _parseResponse(response.data);

      final token = data["Token"];

      if (token == null || token.toString().isEmpty) {
        throw Exception("Token not found in response");
      }

      // 🔥 خزّن التوكن
      await tokenStorage.saveToken(token);

      return AuthUser(token: token);
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await tokenStorage.clearToken();
  }

  String _basicAuth(String username, String password) {
    final credentials = "$username:$password";
    return base64Encode(utf8.encode(credentials));
  }

  Map<String, dynamic> _parseResponse(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return {"message": data};
      }
    }
    return {};
  }
}
