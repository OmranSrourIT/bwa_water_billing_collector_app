import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class InvoiceAttachmentLocalService {
  final AppDatabase db;

  InvoiceAttachmentLocalService(this.db);

   Future<void> saveAttachment({
  required String invoiceNo,
  required String type,
  String? reasonCode,
  required String path,
  int synced = 1,
}) async {
  final database = await db.database;

  await database.insert(
    "invoice_attachments",
    {
      "invoice_no": invoiceNo,
      "type": type,
      "reason_code": reasonCode,
      "path": path,
      "synced": synced,
      "created_at": DateTime.now().toIso8601String(),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

  Future<String?> getAttachment({
    required String invoiceNo,
    required String type,
    String? reasonCode,
  }) async {
    final database = await db.database;

    final result = await database.query(
      "invoice_attachments",
      where: reasonCode == null
          ? "invoice_no = ? AND type = ?"
          : "invoice_no = ? AND type = ? AND reason_code = ?",
      whereArgs: reasonCode == null
          ? [invoiceNo, type]
          : [invoiceNo, type, reasonCode],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first["path"] as String?;
  }

  Future<void> deleteAttachment({
    required String invoiceNo,
    required String type,
  }) async {
    final database = await db.database;

    await database.delete(
      "invoice_attachments",
      where: "invoice_no = ? AND type = ?",
      whereArgs: [invoiceNo, type],
    );
  }

  Future<void> updateAttachment({
    required String invoiceNo,
    required String type,
    required String path,
  }) async {
    final database = await db.database;

    await database.update(
      "invoice_attachments",
      {"path": path},
      where: "invoice_no = ? AND type = ?",
      whereArgs: [invoiceNo, type],
    );
  }
}
