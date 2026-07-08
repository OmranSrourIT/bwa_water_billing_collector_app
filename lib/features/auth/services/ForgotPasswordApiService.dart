import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'forgot_password_service.dart';

class ForgotPasswordApiService implements ForgotPasswordService {
  final Dio dio;

  ForgotPasswordApiService(this.dio);

  @override
  Future<String> sendResetEmail(String email) async {
    try {
      final response = await dio.post(ApiConstants.forgotPassword,
        data: {
          "Email": email,
        },
      ); 
      return response.data.toString();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
