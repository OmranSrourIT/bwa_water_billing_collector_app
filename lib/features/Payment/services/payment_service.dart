import 'dart:convert';

import 'package:bwa_water_billing_collector_app/features/Payment/model/PaymentResponse.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/model/payment_request_model.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';

 
class PaymentService {
  final Dio dio;

  PaymentService({
    required this.dio,
  });

  Future<PaymentResponse> sendPayment(
    PaymentRequest request,
  ) async {
    final response = await dio.post(
      ApiConstants.payment,
      data: {
        "InvoiceNo": request.invoiceNo,
        "tranId": request.tranId,
        "trace": request.trace,
        "rrn": request.rrn,
        "tranType": request.tranType,
        "tranStatus": request.tranStatus,
        "approvalCode": request.approvalCode,
        "paymentMethod": request.paymentMethod,
        "entryMode": request.entryMode,
        "maskedAccount": request.maskedAccount,
        "cvmPerformed": request.cvmPerformed,
        "acqMid": request.acqMid,
        "acqTid": request.acqTid,
        "posMessageId": request.posMessageId,
        "mchAddress": request.mchAddress,
        "mchName": request.mchName,
        "totalAmount": request.totalAmount,
        "createByName": request.createByName,
        "createdAt": request.createdAt,
        "updatedAt": request.updatedAt,
        "amount": request.amount,
        "description": request.description,
      },
    );

    dynamic data = response.data;

    if (data is String) {
      data = jsonDecode(data);
    }

    if (data is Map<String, dynamic>) {
      if (data["Result"] != null) {
        return PaymentResponse.success(data);
      }

      if (data["error"] != null) {
        return PaymentResponse.error({
          "AR_message": data["error"]["message"],
          "EN_message": data["error"]["message"],
        });
      }
    }

    throw Exception("Unexpected response");
  }
}
