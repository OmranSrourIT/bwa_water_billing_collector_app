import 'dart:convert';

import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/model/pos_payment_models.dart';
import 'package:dio/dio.dart';

class PosPaymentService {
  final Dio dio;

  PosPaymentService({
    required this.dio,
  });

  Future<PosInvoiceActionResponse> reserveInvoice({
    required String invoiceNo,
    required String posReference,
  }) async {
    return _postInvoiceAction(
      ApiConstants.updatePosId,
      {
        "InvoiceNo": invoiceNo,
        "Action": posReference,
      },
    );
  }

  Future<PosInvoiceActionResponse> releaseInvoice({
    required String invoiceNo,
  }) async {
    return _postInvoiceAction(
      ApiConstants.updateSendToPosFalse,
      {
        "InvoiceNo": invoiceNo,
      },
    );
  }

  Future<PaymentStatusCheckResponse> checkPayment({
    required String invoiceNo,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.checkPaymentStatus,
        data: {
          "InvoiceNo": invoiceNo,
        },
        options: Options(
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      return PaymentStatusCheckResponse.fromJson(
        _convertToMap(response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      final response = error.response;

      if (response != null) {
        return PaymentStatusCheckResponse.fromJson(
          _convertToMap(response.data),
          statusCode: response.statusCode,
        );
      }

      rethrow;
    }
  }

  Future<PosInvoiceActionResponse> _postInvoiceAction(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await dio.post(
        endpoint,
        data: body,
        options: Options(
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      return PosInvoiceActionResponse.fromJson(
        _convertToMap(response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      final response = error.response;

      if (response != null) {
        return PosInvoiceActionResponse.fromJson(
          _convertToMap(response.data),
          statusCode: response.statusCode,
        );
      }

      rethrow;
    }
  }

  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String && data.trim().isNotEmpty) {
      final decodedData = jsonDecode(data);

      if (decodedData is Map) {
        return Map<String, dynamic>.from(decodedData);
      }
    }

    return <String, dynamic>{};
  }
}
