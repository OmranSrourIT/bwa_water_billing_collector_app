 
import 'package:bwa_water_billing_collector_app/features/Payment/model/PaymentResponse.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/model/payment_request_model.dart';

import '../services/payment_service.dart';

class PaymentRepository {
  final PaymentService api;

  PaymentRepository({
    required this.api,
  });

  Future<PaymentResponse> sendPayment(
    PaymentRequest request,
  ) {
    return api.sendPayment(request);
  }
}
