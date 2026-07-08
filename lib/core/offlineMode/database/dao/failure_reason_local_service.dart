import 'dart:convert';

import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonRequestModel.dart';

class FailureReasonLocalService {
  final AppDatabase db;

  FailureReasonLocalService(this.db);

  Future<void> saveFailureReason(FailureReasonRequest request) async {
    final database = await db.database;

    await database.insert("sync_queue", {
      "type": "FAILURE_REASON",

      "reference_no": request.invoiceNo,

      "payload": jsonEncode({
        "invoiceNo": request.invoiceNo,

        "code": request.code,

        "notes": request.notes,

        "failureReason": request.failureReason,

        "base64": request.base64,
      }),

      "status": "pending",

      "retries": 0,

      "created_at": DateTime.now().toIso8601String(),
    });
  }
}
