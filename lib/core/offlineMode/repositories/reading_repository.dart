import 'package:bwa_water_billing_collector_app/core/constants/attachment_type.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_attachment_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_details_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/sync_queue_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/storage/image_storage_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/ReadingResponse.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/reading_request_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/reading_service.dart';

class ReadingRepository {
  final ReadingService api;

  final SyncQueueLocalService queue;
  final InvoiceDetailsLocalService local;
  final InvoiceAttachmentLocalService attachmentLocal;
  final ImageStorageService imageStorage;
  final bool isOnline;

  ReadingRepository({
    required this.api,
    required this.queue,
    required this.local,
    required this.attachmentLocal,
    required this.imageStorage,
    required this.isOnline,
  });

  Future<ReadingResponse> insertReading(ReadingRequest request) async {
    if (isOnline) {
      return await api.insertReading(
        invoiceNumber: request.invoiceNumber,

        previousReading: request.previousReading,

        currentReading: request.currentReading,

        currentReadDateTime: request.currentReadDateTime,

        previousReadingDateTime: request.previousReadingDateTime,

        isMeterRollover: request.isMeterRollover,

        latitude: request.latitude,

        longitude: request.longitude,

        base64: request.base64,
      );
    }

    // OFFLINE

    String? imagePath;

    if (request.base64 != null && request.base64!.isNotEmpty) {
      imagePath = await imageStorage.saveInvoiceImage(
        invoiceNo: request.invoiceNumber,
        type: AttachmentType.meter,
        base64: request.base64,
      );

      if (imagePath != null) {
        await attachmentLocal.saveAttachment(
          invoiceNo: request.invoiceNumber,
          type: AttachmentType.meter,
          path: imagePath,
          synced: 0,
        );
      }
    }

    await queue.addQueue(
      type: "READING",
      referenceNo: request.invoiceNumber,
      payload: {
        "invoiceNumber": request.invoiceNumber,
        "previousReading": request.previousReading,
        "currentReading": request.currentReading,
        "currentReadDateTime": request.currentReadDateTime,
        "previousReadingDateTime": request.previousReadingDateTime,
        "isMeterRollover": request.isMeterRollover,
        "latitude": request.latitude,
        "longitude": request.longitude,

        // لم يعد Base64
        "imagePath": imagePath,
      },
    );

    await local.updateReading(
      invoiceNo: request.invoiceNumber,
      currentReading: request.currentReading,
      currentReadDateTime: DateTime.parse(request.currentReadDateTime),
      
    );

    return ReadingResponse(
      isSuccess: true,

      result: "PENDING",

      arMessage: "تم حفظ القراءة وسيتم الإرسال عند توفر الإنترنت",

      enMessage: "Saved offline",
    );
  }
}
