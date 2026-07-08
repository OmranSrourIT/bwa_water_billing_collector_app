import 'package:dio/dio.dart';

import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/HandelError.dart';

import 'change_password_service.dart';

class ChangePasswordApiService implements ChangePasswordService {
  final Dio dio;

  ChangePasswordApiService(this.dio);

  @override
  Future<String> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.changePassword,
        data: {"NewPassword": newPassword, "ConfirmPassword": confirmPassword},
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        if (data["Result"] != null) {
          return data["Result"];
        }

        if (data["message"] != null) {
          throw data["message"]; // 👈 بدل Exception
        }
      }
      return "Password updated successfully";
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
