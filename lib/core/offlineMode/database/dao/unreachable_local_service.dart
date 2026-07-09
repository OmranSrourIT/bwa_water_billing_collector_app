 
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/app_database.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonRequestModel.dart';

class UnreachableLocalService {
  final AppDatabase db;

  UnreachableLocalService(this.db);

  Future<void> insert(FailureReasonRequest request) async {
    final database = await db.database;

    await database.insert("unreachable", {
      "invoice_no": request.invoiceNo,

      "failure_reason_code": request.code,

      "failure_reason": request.failureReason,

      "failure_notes": request.notes,

      "attachment": request.base64,

      "created_at": DateTime.now().toIso8601String(),

      "synced": 0,
    });
  }
}
