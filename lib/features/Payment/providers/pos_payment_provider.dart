 
import 'package:bwa_water_billing_collector_app/features/Payment/Repository/PosPaymentRepository.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/services/pos_payment_service.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final posPaymentServiceProvider = Provider<PosPaymentService>((ref) {
  final dio = ref.watch(dioProvider);

  return PosPaymentService(
    dio: dio,
  );
});

final posPaymentRepositoryProvider = Provider<PosPaymentRepository>((ref) {
  final service = ref.watch(posPaymentServiceProvider);

  return PosPaymentRepository(
    api: service,
  );
});
