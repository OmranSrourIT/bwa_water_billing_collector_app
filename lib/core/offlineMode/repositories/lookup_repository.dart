import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/lookup_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/field_failure_lookup_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/FieldFailureLookupService.dart';

class LookupRepository {
  final FieldFailureLookupService api;
  final LookupLocalService local;

  final bool isOnline;

  LookupRepository({
    required this.api,
    required this.local,
    required this.isOnline,
  });

  Future<List<FieldFailureLookupModel>> getLookups(
    String lookupType,
  ) async {
    if (isOnline) {
      final lookups = await api.getLookupStatus(lookupType); 
      return lookups;
    }

    print("Offline => SQLite Lookups");

    return await local.getLookups(lookupType);
  }
}
