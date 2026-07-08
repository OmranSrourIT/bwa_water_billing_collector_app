import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/sync_queue_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/ReadingResponse.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/reading_request_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/reading_service.dart';

class ReadingRepository {
  final ReadingService api;

  final SyncQueueLocalService queue;

  final bool isOnline;

  ReadingRepository({
    required this.api,
    required this.queue,
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

        "base64": request.base64,
      },
    );

    return ReadingResponse(
      isSuccess: true,

      result: "PENDING",

      arMessage: "تم حفظ القراءة وسيتم الإرسال عند توفر الإنترنت",

      enMessage: "Saved offline",
    );
  }
}
