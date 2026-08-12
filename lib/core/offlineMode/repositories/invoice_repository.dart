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
 

    if (!isOnline) {
      return await local.getInvoices(batchNumber);
    }

 

    final invoices = await api.getInvoices(batchNumber);

    // ترتيب الفواتير
    invoices.sort(
      (a, b) => a.accountNo.compareTo(b.accountNo),
    );

    // =========================================================
    // SAVE INVOICES LOCALLY
    // =========================================================

    await local.insertInvoices(
      batchNumber,
      invoices,
    );

    // =========================================================
    // ONLY INVOICES THAT REQUIRE READING
    //
    // UEX = تعذر القراءة أو التنفيذ
    // ISS = قيد التنفيذ
    // =========================================================

    final readingInvoices = invoices.where((invoice) {
      final status = invoice.lookup.firstWhere(
        (e) => e.lookupType == "InvoiceStatus",
        orElse: () => invoice.lookup.first,
      );

      return status.code == "UEX" || status.code == "ISS";
    }).toList();

    // =========================================================
    // DOWNLOAD DETAILS
    //
    // مهم:
    // لا نحمل Details للفواتير COL / RDY / UNC
    // =========================================================

    await _downloadInvoiceDetailsInChunks(
      readingInvoices,
    );

    return invoices;
  }

  // =========================================================
  // DOWNLOAD DETAILS WITH LIMITED CONCURRENCY
  // =========================================================

  Future<void> _downloadInvoiceDetailsInChunks(
    List<InvoiceModel> invoices,
  ) async {
    if (invoices.isEmpty) {
      return;
    }

    // عدد الطلبات المتزامنة
    const chunkSize = 8;

    for (int i = 0; i < invoices.length; i += chunkSize) {
      final chunk = invoices
          .skip(i)
          .take(chunkSize)
          .toList();

      await Future.wait(
        chunk.map(
          (invoice) async {
            try {
              await detailsRepository.downloadInvoiceDetails(
                invoice.invoiceNo,
              );
            } catch (e) {
              // لا نوقف تحميل باقي الفواتير
              print(
                'Failed to download invoice details '
                '${invoice.invoiceNo}: $e',
              );
            }
          },
        ),
      );
    }
  }
}
