import 'package:bwa_water_billing_collector_app/features/Payment/Repository/PaymentRepository.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/model/PaymentResponse.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/model/payment_request_model.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/services/payment_service.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);

  return PaymentService(dio: dio);
});

final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) {
  return PaymentRepository(
    api: ref.read(paymentServiceProvider),
  );
});

final paymentProvider =
    FutureProvider.family<PaymentResponse, PaymentRequest>(
        (ref, request) async {
  final repository = ref.read(paymentRepositoryProvider);

  return repository.sendPayment(request);
});
