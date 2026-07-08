import 'dart:convert';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/reading_request_model.dart';

class ReadingLocalService {
  final AppDatabase db;

  ReadingLocalService(this.db);

  Future<void> saveReading(ReadingRequest request) async {
    final database = await db.database;

    await database.insert("sync_queue", {
      "type": "READING",

      "reference_no": request.invoiceNumber,

      "payload": jsonEncode({
        "invoiceNumber": request.invoiceNumber,

        "previousReading": request.previousReading,

        "currentReading": request.currentReading,

        "currentReadDateTime": request.currentReadDateTime,

        "previousReadingDateTime": request.previousReadingDateTime,

        "isMeterRollover": request.isMeterRollover,

        "latitude": request.latitude,

        "longitude": request.longitude,

        "base64": request.base64,
      }),

      "status": "pending",

      "retries": 0,

      "created_at": DateTime.now().toIso8601String(),
    });
  }
}
