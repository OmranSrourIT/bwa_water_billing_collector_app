import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/invoice_repository.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoice_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/InvoiceApiService.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoice_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceApiService(ref.read(dioProvider));
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(
    api: ref.read(invoiceServiceProvider),
    local: ref.read(invoiceLocalServiceProvider),
     isOnline:ref.watch(connectionProvider),
  );
});

final invoicesProvider = FutureProvider.family<List<InvoiceModel>, String>((ref,batchId,)
 async {
  final repository = ref.read(invoiceRepositoryProvider);
  return repository.getInvoices(batchId);
});
