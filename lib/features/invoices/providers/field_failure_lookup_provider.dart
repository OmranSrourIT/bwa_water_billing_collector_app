import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/lookup_repository.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/field_failure_lookup_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/FieldFailureLookupService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';


final fieldFailureLookupServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);

  return FieldFailureLookupService(dio);
});


final lookupRepositoryProvider = Provider<LookupRepository>((ref) {
  return LookupRepository(
    api: ref.read(fieldFailureLookupServiceProvider),
    local: ref.read(lookupLocalServiceProvider),
    isOnline: ref.watch(connectionProvider),
  );
});


final fieldFailureLookupProvider =
    FutureProvider.family<List<FieldFailureLookupModel>, String>((
      ref,
      lookupStatus,
    ) async {
      final repository = ref.watch(lookupRepositoryProvider);

      return repository.getLookups(lookupStatus);
    });
