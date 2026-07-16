import 'package:bwa_water_billing_collector_app/core/constants/attachment_type.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_attachment_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_details_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/sync_queue_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/storage/image_storage_service.dart';

import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonRequestModel.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonResponse.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/failure_reason_service.dart';

class FailureReasonRepository {
  final FailureReasonService api;
  final SyncQueueLocalService queue;
  final InvoiceDetailsLocalService detailsLocal;
  final InvoiceAttachmentLocalService attachmentLocal;
  final ImageStorageService imageStorage;
  final bool isOnline;

  FailureReasonRepository({
    required this.api,
    required this.queue,
    required this.detailsLocal,
    required this.attachmentLocal,
    required this.imageStorage,
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

    String? imagePath;

    if (request.base64 != null && request.base64!.isNotEmpty) {
      imagePath = await imageStorage.saveInvoiceImage(
        invoiceNo: request.invoiceNo,
        type: AttachmentType.failure,
        base64: request.base64,
      );

      if (imagePath != null) {
        await attachmentLocal.saveAttachment(
          invoiceNo: request.invoiceNo,
          type: AttachmentType.failure,
          reasonCode: request.code,
          path: imagePath,
          synced: 0,
        );
      }
    }

    await queue.addQueue(
      type: "FAILURE_REASON",
      referenceNo: request.invoiceNo,
      payload: {
        "invoiceNo": request.invoiceNo,
        "code": request.code,
        "notes": request.notes,
        "failureReason": request.failureReason,

        // بدلاً من Base64
        "imagePath": imagePath,
      },
    );

    await detailsLocal.updateFailureReason(
      invoiceNo: request.invoiceNo,
      code: request.code,
      notes: request.notes,
      attachment: imagePath,
    );

    return FailureReasonResponse(
      result: "PENDING",
      arMessage: "تم الحفظ وسيتم الإرسال عند توفر الإنترنت",
      enMessage: "Saved offline",
    );
  }
}
