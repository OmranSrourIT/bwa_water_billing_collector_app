import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/initial_sync_repository.dart';
import 'package:bwa_water_billing_collector_app/features/Account/services/account_api_service.dart';
import 'package:bwa_water_billing_collector_app/features/batch/services/batch_Api_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/FieldFailureLookupService.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/InvoiceApiService.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoiceDetials_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';

final initialSyncProvider = Provider<InitialSyncRepository>((ref) {
  return InitialSyncRepository(
    batchApi: BatchApiService(ref.watch(dioProvider)),
    invoiceApi: InvoiceApiService(ref.watch(dioProvider)),
    detailsApi: InvoiceDetailsService(ref.watch(dioProvider)),
    lookupApi: FieldFailureLookupService(ref.watch(dioProvider)),
    accountApi: AccountApiService(ref.watch(dioProvider)),
    batchLocal: ref.read(batchLocalServiceProvider),
    invoiceLocal: ref.read(invoiceLocalServiceProvider),
    detailsLocal: ref.read(invoiceDetailsLocalServiceProvider),
    lookupLocal: ref.read(lookupLocalServiceProvider),
    accountLocal: ref.read(accountLocalServiceProvider),
  );
});
