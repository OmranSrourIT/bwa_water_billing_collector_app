import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_details_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/sync_queue_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/reading_service.dart';

class UpdateInvoiceStatusRepository {
  final ReadingService api;
  final SyncQueueLocalService queue;
  final InvoiceDetailsLocalService detailsLocal;
  final InvoiceLocalService invoiceLocal;
  final bool isOnline;

  UpdateInvoiceStatusRepository({
    required this.api,
    required this.queue,
    required this.detailsLocal,
    required this.invoiceLocal,
    required this.isOnline,
  });

  Future<String> updateStatus({
    required String invoiceNo,
    required String status,
  }) async {
    if (isOnline) {
      return await api.updateInvoiceStatus(
        invoiceNumber: invoiceNo,
        status: status,
      );
    }

    /// Offline
    await queue.addQueue(
      type: "UPDATE_INVOICE_STATUS",
      referenceNo: invoiceNo,
      payload: {"invoiceNo": invoiceNo, "status": status},
    );

    await detailsLocal.updateInvoiceStatus(
      invoiceNo: invoiceNo,
      status: status,
    );

    await invoiceLocal.updateInvoiceStatus(
      invoiceNo: invoiceNo,
      status: status,
    );
    return "PENDING";
  }
}
