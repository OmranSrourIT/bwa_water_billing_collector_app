import 'package:bwa_water_billing_collector_app/features/invoices/services/FieldFailureLookupService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/field_failure_lookup_model.dart';

final fieldFailureLookupServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);

  return FieldFailureLookupService(dio: dio);
});

final fieldFailureLookupProvider =
    FutureProvider.family<List<FieldFailureLookupModel>, String>((
      ref,
      lookupStatus,
    ) async {
      final service = ref.read(fieldFailureLookupServiceProvider);

      return service.getLookupStatus(lookupStatus);
    });


    
