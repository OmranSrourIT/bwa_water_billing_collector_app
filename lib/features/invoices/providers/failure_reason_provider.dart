import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/failure_reason_repository.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonRequestModel.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonResponse.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/failure_reason_service.dart';
import '../../auth/providers/auth_provider.dart';

final failureReasonServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);

  return FailureReasonService(dio: dio);
});

final failureReasonRepositoryProvider = Provider<FailureReasonRepository>((
  ref,
) {
  return FailureReasonRepository(
    api: ref.read(failureReasonServiceProvider),
    queue: ref.read(syncQueueLocalServiceProvider),
    detailsLocal: ref.read(invoiceDetailsLocalServiceProvider),
    isOnline: ref.watch(connectionProvider),
  );
});

final failureReasonProvider =
    FutureProvider.family<FailureReasonResponse, FailureReasonRequest>((
      ref,
      request,
    ) async {
      final repository = ref.watch(failureReasonRepositoryProvider);

      return repository.sendFailureReason(request);
    });
