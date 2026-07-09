import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/reading_repository.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/ReadingResponse.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

import '../models/reading_request_model.dart';

import '../services/reading_service.dart';

final readingServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);

  return ReadingService(dio: dio);
});
 
 final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return ReadingRepository(
    api: ref.read(readingServiceProvider),
    queue: ref.read(syncQueueLocalServiceProvider),
    local: ref.read(invoiceDetailsLocalServiceProvider),
    isOnline: ref.watch(connectionProvider),
  );
});

final insertReadingProvider =
    FutureProvider.family<ReadingResponse, ReadingRequest>((
      ref,
      request,
    ) async {
      final repository = ref.watch(readingRepositoryProvider);

      return repository.insertReading(request);
    });



    
final updateInvoiceStatusProvider =
    FutureProvider.family<String, ({String invoiceNo, String status})>((
      ref,
      request,
    ) async {
      final service = ref.read(readingServiceProvider);

      return service.updateInvoiceStatus(
        invoiceNumber: request.invoiceNo,
        status: request.status,
      );
    });
