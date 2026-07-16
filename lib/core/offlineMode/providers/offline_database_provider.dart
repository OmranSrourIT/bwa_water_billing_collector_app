import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/AccountLocalService.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/batch_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_attachment_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_details_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/lookup_local_service.dart'; 
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/sync_queue_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/image_storage_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/sync/sync_engine.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/failure_reason_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/reading_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/dao/invoice_local_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final batchLocalServiceProvider = Provider<BatchLocalService>((ref) {
  return BatchLocalService(ref.read(databaseProvider));
});

final invoiceLocalServiceProvider = Provider<InvoiceLocalService>((ref) {
  return InvoiceLocalService(ref.read(databaseProvider),ref.read(lookupLocalServiceProvider));
});

final invoiceDetailsLocalServiceProvider = Provider<InvoiceDetailsLocalService>(
  (ref) {
    return InvoiceDetailsLocalService(ref.read(databaseProvider), ref.read(invoiceAttachmentLocalServiceProvider),ref.read(lookupLocalServiceProvider));
  },
);


final syncQueueLocalServiceProvider = Provider<SyncQueueLocalService>((ref) {
  return SyncQueueLocalService(ref.read(databaseProvider));
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    queue: ref.read(syncQueueLocalServiceProvider),

    readingService: ref.read(readingServiceProvider),

    failureReasonService: ref.read(failureReasonServiceProvider),
    imageStorage: ref.read(imageStorageProvider)
  );
});

final lookupLocalServiceProvider = Provider<LookupLocalService>((ref) {
  return LookupLocalService(ref.read(databaseProvider));
});


final accountLocalServiceProvider = Provider<AccountLocalService>((ref) {
  return AccountLocalService(ref.read(databaseProvider));
});

final invoiceAttachmentLocalServiceProvider =
    Provider<InvoiceAttachmentLocalService>((ref) {
  return InvoiceAttachmentLocalService(
    ref.read(databaseProvider),
  );
});

