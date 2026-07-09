import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/sync_queue_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/unreachable_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonRequestModel.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonResponse.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/failure_reason_service.dart';

class FailureReasonRepository {
  final FailureReasonService api;
  final SyncQueueLocalService queue;
  final UnreachableLocalService unreachable;
  final bool isOnline;

  FailureReasonRepository({
    required this.api,
    required this.queue,
    required this.unreachable,
    required this.isOnline,
  });

  Future<FailureReasonResponse> sendFailureReason(
    FailureReasonRequest request,
  ) async {

    if (isOnline) {
      return await api.sendFailureReason(
        invoiceNo: request.invoiceNo,
        failureReasonCode: request.code,
        failureNotes: request.notes,
        failureReason: request.failureReason,
        base64Image: request.base64,
      );
    }

    // حفظ بالتعذرات
    await unreachable.insert(request);

    // حفظ بالـ Queue
    await queue.addQueue(
      type: "FAILURE_REASON",
      referenceNo: request.invoiceNo,
      payload: {
        "invoiceNo": request.invoiceNo,
        "code": request.code,
        "notes": request.notes,
        "failureReason": request.failureReason,
        "base64": request.base64,
      },
    );

    return FailureReasonResponse(
      result: "PENDING",
      arMessage: "تم الحفظ وسيتم الإرسال عند توفر الإنترنت",
      enMessage: "Saved offline",
    );
  }
}
