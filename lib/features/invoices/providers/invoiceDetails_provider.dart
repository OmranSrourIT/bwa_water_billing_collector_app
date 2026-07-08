import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/invoice_details_repository.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoiceDetials_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceServiceDetailsProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return InvoiceDetailsService(dio);
});

final invoiceDetailsRepositoryProvider = Provider<InvoiceDetailsRepository>((
  ref,
) {
  return InvoiceDetailsRepository(
    api: ref.read(invoiceServiceDetailsProvider),
    local: ref.read(invoiceDetailsLocalServiceProvider),
    isOnline: ref.watch(connectionProvider),
  );
});

final invoiceDetailProvider =
    FutureProvider.family<InvoiceInformationModel, String>((
      ref,
      invoiceNumber,
    ) async {
      final repository = ref.read(invoiceDetailsRepositoryProvider);

      return repository.getInvoice(invoiceNumber);
    });

final updateNoticePrintProvider = FutureProvider.family<String, String>((
  ref,
  invoiceNo,
) async {
  final service = ref.watch(invoiceServiceDetailsProvider);
  return service.updateNoticePrint(invoiceNo);
});
