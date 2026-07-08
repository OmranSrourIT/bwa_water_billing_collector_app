import 'dart:convert';

import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonResponse.dart';
import 'package:dio/dio.dart';

class FailureReasonService {
  final Dio dio;

  FailureReasonService({required this.dio});

  Future<FailureReasonResponse> sendFailureReason({
    required String invoiceNo,
    required String failureReasonCode,
    required String failureNotes,
    required String failureReason,
    String? base64Image,
  }) async {
    final response = await dio.post(
      ApiConstants.failureReason,
      data: {
         "InvoiceNo":invoiceNo,
        "FailureNotes": failureNotes,
        "FailureReasonCode": failureReasonCode,
        "FailureReasons": failureReason,
        "Attachment": {
          "FileExtention": base64Image != null ? "JPG" : "",
          "Base64": base64Image ?? "",
        }
      },
    );

    final data = response.data;

    if (data is String) {
      return FailureReasonResponse.fromJson(jsonDecode(data));
    }

    return FailureReasonResponse.fromJson(data);
  }
}
