import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/batch_repository.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/batch/models/BatchEndResponse.dart';
import 'package:bwa_water_billing_collector_app/features/batch/models/batch_model.dart';
import 'package:bwa_water_billing_collector_app/features/batch/services/batch_Api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final batchServiceProvider = Provider<BatchApiService>((ref) {
  return BatchApiService(ref.watch(dioProvider));
});

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return BatchRepository(
    api: ref.watch(batchServiceProvider), 
    local: ref.watch(batchLocalServiceProvider),
     isOnline:ref.watch(connectionProvider),
  );
});

final batchProvider = FutureProvider<List<BatchModel>>((ref) async {
  final repository = ref.watch(batchRepositoryProvider); 
  return repository.getBatches();
});

final endBatchProvider = FutureProvider.family<BatchEndResponse, String>((
  ref,
  batchId,
) async {
  final service = ref.read(batchServiceProvider);
  return service.endBatch(batchId);
});
