import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/batch_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_details_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/lookup_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/batch/services/batch_Api_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/FieldFailureLookupService.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoice_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoiceDetials_service.dart';

import '../database/dao/invoice_local_service.dart';

class InitialSyncRepository {
  final BatchApiService batchApi;
  final InvoiceService invoiceApi;
  final InvoiceDetailsService detailsApi;
  final FieldFailureLookupService lookupApi;
  final BatchLocalService batchLocal;
  final InvoiceLocalService invoiceLocal;
  final InvoiceDetailsLocalService detailsLocal;
  final LookupLocalService lookupLocal;

  InitialSyncRepository({
    required this.batchApi,
    required this.invoiceApi,
    required this.detailsApi,
    required this.lookupApi,
    required this.batchLocal,
    required this.invoiceLocal,
    required this.detailsLocal,
    required this.lookupLocal,
  });

  Future<void> downloadInitialData({
    Function(String message)? onProgress,
  }) async {
    try {
      onProgress?.call("جاري تجهيز البيانات محليا...");

      final batches = await batchApi.getBatches();

      await batchLocal.insertBatches(batches);

      final lookupType = "FieldFailureReason";

      final lookups = await lookupApi.getLookupStatus(lookupType);

      await lookupLocal.insertLookups(lookupType, lookups);

      for (final batch in batches) {
        final invoices = await invoiceApi.getInvoices(batch.batchNumber);
        await invoiceLocal.insertInvoices(batch.batchNumber, invoices);

        for (final invoice in invoices) {
          final details = await detailsApi.getInvoice(invoice.invoiceNo);

          await detailsLocal.insertInvoiceDetails(details);
        }
      }

      onProgress?.call("تم تحميل جميع البيانات بنجاح");
    } catch (e) {
      onProgress?.call("حدث خطأ أثناء تحميل البيانات");

      rethrow;
    }
  }
}
