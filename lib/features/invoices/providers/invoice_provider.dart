import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/invoice_repository.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoice_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/InvoiceApiService.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoice_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  final dio = ref.watch(dioProvider);

  return InvoiceApiService(dio);
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final api = ref.watch(invoiceServiceProvider);
  final local = ref.watch(invoiceLocalServiceProvider);
  final detailsRepository = ref.watch(invoiceDetailsRepositoryProvider);
  final isOnline = ref.watch(connectionProvider);

  return InvoiceRepository(
    api: api,
    local: local,
    detailsRepository: detailsRepository,
    isOnline: isOnline,
  );
});

final invoicesProvider =
    FutureProvider.autoDispose.family<List<InvoiceModel>, String>(
  (ref, batchId) async {
    final repository = ref.watch(invoiceRepositoryProvider);

    ref.onDispose(() {
      print('[INVOICES PROVIDER DISPOSED] batchId=$batchId');
    });

    print('[INVOICES REQUEST] batchId=$batchId');

    return repository.getInvoices(batchId);
  },
);
