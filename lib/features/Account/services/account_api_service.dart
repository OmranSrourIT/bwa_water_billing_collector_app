import 'package:dio/dio.dart';

import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/features/Account/model/account_model.dart';
import 'package:bwa_water_billing_collector_app/features/Account/services/account_service.dart';

class AccountApiService implements AccountService {
  final Dio dio;

  AccountApiService(this.dio);

  @override
  Future<AccountModel> getAccount() async {
    final response = await dio.get(
      ApiConstants.accountDetail,
    );

    final json = response.data;

    return AccountModel(
      firstNameAr: json["ArFirstName"] ?? "",
      fatherNameAr: json["ArSecondName"] ?? "",
      grandfatherNameAr: json["ArThirdName"] ?? "",
      familyNameAr: json["ArFamilyName"] ?? "",

      firstNameEn: json["EnFirstName"] ?? "",
      fatherNameEn: json["EnSecondName"] ?? "",
      grandfatherNameEn: json["EnThirdName"] ?? "",
      familyNameEn: json["EnFamilyName"] ?? "",

      username: json["Username"] ?? "",
      email: json["Email"] ?? "",

      nationalId: json["EmployeeNumber"] ?? "",
      phone: json["MobileNumber"] ?? "",
      countryCode: "",

      unifiedCardNo: "",

      nationalNumber: json["National_ID"] ?? "",
    );
  }
}
