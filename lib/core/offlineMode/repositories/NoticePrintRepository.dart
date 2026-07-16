import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/sync_queue_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoiceDetials_service.dart';

class NoticePrintRepository {
  final InvoiceDetailsService api;
  final SyncQueueLocalService queue;
  final bool isOnline;

  NoticePrintRepository({
    required this.api,
    required this.queue,
    required this.isOnline,
  });

  Future<String> updateNoticePrint(String invoiceNo) async {
    if (isOnline) {
      return await api.updateNoticePrint(invoiceNo);
    }

    await queue.addQueue(
      type: "UPDATE_NOTICE_PRINT",
      referenceNo: invoiceNo,
      payload: {
        "invoiceNo": invoiceNo,
      },
    );

    return "PENDING";
  }
}
