import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/image_storage_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/NoticePrintRepository.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/invoice_details_repository.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoiceDetials_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceServiceDetailsProvider =
    Provider<InvoiceDetailsService>((ref) {
  final dio = ref.watch(dioProvider);

  return InvoiceDetailsService(dio);
});

final invoiceDetailsRepositoryProvider =
    Provider<InvoiceDetailsRepository>((ref) {
  return InvoiceDetailsRepository(
    api: ref.watch(invoiceServiceDetailsProvider),
    local: ref.watch(invoiceDetailsLocalServiceProvider),
    attachmentLocal: ref.watch(invoiceAttachmentLocalServiceProvider),
    imageStorage: ref.watch(imageStorageProvider),
    isOnline: ref.watch(connectionProvider),
  );
});

final invoiceDetailProvider = FutureProvider.autoDispose
    .family<InvoiceInformationModel, String>(
  (ref, invoiceNumber) async {
    final repository = ref.watch(
      invoiceDetailsRepositoryProvider,
    );

    return repository.getInvoiceDeatils(invoiceNumber);
  },
);

final noticePrintRepositoryProvider =
    Provider<NoticePrintRepository>((ref) {
  return NoticePrintRepository(
    api: ref.watch(invoiceServiceDetailsProvider),
    queue: ref.watch(syncQueueLocalServiceProvider),
    isOnline: ref.watch(connectionProvider),
  );
});

final updateNoticePrintProvider =
    FutureProvider.autoDispose.family<String, String>(
  (ref, invoiceNo) async {
    final repository = ref.watch(
      noticePrintRepositoryProvider,
    );

    return repository.updateNoticePrint(invoiceNo);
  },
);

final ensureInvoiceDetailsProvider = FutureProvider.autoDispose
    .family<InvoiceInformationModel, String>(
  (ref, invoiceNumber) async {
    final repository = ref.watch(
      invoiceDetailsRepositoryProvider,
    );

    return repository.ensureInvoiceDetails(invoiceNumber);
  },
);
