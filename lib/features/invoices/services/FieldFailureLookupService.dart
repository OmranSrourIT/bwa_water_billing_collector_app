import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/field_failure_lookup_model.dart';
import 'package:dio/dio.dart';

class FieldFailureLookupService {
  final Dio dio;

  FieldFailureLookupService({required this.dio}); 
   Future<List<FieldFailureLookupModel>> getLookupStatus(
    String lookUpstatus,
  ) async {
    final response = await dio.get(ApiConstants.lookupStatus(lookUpstatus));

    final data = response.data as List;

    return data.map((e) => FieldFailureLookupModel.fromJson(e)).toList();
  }
}
