import 'dart:convert';

import 'package:bwa_water_billing_collector_app/features/invoices/models/ReadingResponse.dart';
import 'package:dio/dio.dart';
import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';

class ReadingService {
  final Dio dio;

  ReadingService({required this.dio});

  Future<ReadingResponse> insertReading({
    required String invoiceNumber,
    required double previousReading,
    required double currentReading,
    required String currentReadDateTime,
    required String previousReadingDateTime,
    required bool isMeterRollover,
    required String latitude,
    required String longitude,
    String? base64,
  }) async {
    final response = await dio.post(
      ApiConstants.insertReading,

      data: {
        "InvoiceNumber": invoiceNumber,

        "PreviousReading": previousReading,

        "CurrentReading": currentReading,

        "CurrentReadDateTime": currentReadDateTime,

        "PreviousReadingDateTime": previousReadingDateTime,

        "IsMeterRollover": isMeterRollover,

        "Coordinates": {"Latitude": latitude, "Longitude": longitude},

        "Attachment": {"Base64": base64 ?? ""},
      },
    );
    dynamic data = response.data;

    if (data is String) {
      data = jsonDecode(data);
    }

    if (data is Map<String, dynamic>) {
      return ReadingResponse.success(data);
    }

    if (data is List && data.isNotEmpty) {
      return ReadingResponse.error(data.first);
    }

    throw Exception("Unexpected response");
  }

  Future<String> updateInvoiceStatus({
    required String invoiceNumber,
    required String status,
  }) async {
    final response = await dio.post(
      ApiConstants.updateInvoiceStatus,
      data: {"InvoiceNo": invoiceNumber, "Action": status},
    );
    dynamic data = response.data;
    if (data is String) {
      data = jsonDecode(data);
    }

    if (data is Map<String, dynamic>) {
      if (data["result"] != null) {
        return data["result"].toString();
      }

      if (data["error"] != null) {
        throw Exception(data["error"]["message"]);
      }
    }

    throw Exception("Unexpected response: $data");
  }
}
