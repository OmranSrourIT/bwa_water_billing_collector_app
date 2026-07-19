import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/invoice_details_repository.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoice_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoice_service.dart';

class InvoiceRepository {
  final InvoiceService api;

  final InvoiceLocalService local;
  final InvoiceDetailsRepository detailsRepository;

  final bool isOnline;

  InvoiceRepository({
    required this.api,
    required this.local,
    required this.detailsRepository,
    required this.isOnline,
  });

  Future<List<InvoiceModel>> getInvoices(String batchNumber) async {
    if (isOnline) {
      final invoices = await api.getInvoices(batchNumber);

      invoices.sort((a, b) => a.accountNo.compareTo(b.accountNo));

      await local.insertInvoices(batchNumber, invoices);

      // for (final invoice in invoices) {
      //   try {
      //     await detailsRepository.downloadInvoiceDetails(invoice.invoiceNo);
      //   } catch (_) {
      //     // لا توقف تحميل الفواتير إذا فشلت فاتورة واحدة
      //   }
      // }

      return invoices;
    }

    final result = await local.getInvoices(batchNumber);
    return result;
  }
}
