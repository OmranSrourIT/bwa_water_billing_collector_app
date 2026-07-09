import 'dart:convert';
 
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SyncQueueLocalService {
  final AppDatabase db;

  SyncQueueLocalService(this.db);

  // إضافة عملية تنتظر المزامنة
  Future<void> addQueue({
    required String type,
    required String referenceNo,
    required Map<String, dynamic> payload,
  }) async {
    final database = await db.database;

    await database.insert("sync_queue", {
      "type": type,
      "reference_no": referenceNo,
      "payload": jsonEncode(payload),

      "status": "pending",

      "retries": 0,

      "created_at": DateTime.now().toIso8601String(),
    });
  }

  // جلب العمليات المعلقة
  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final database = await db.database;

    return await database.query(
      "sync_queue",

      where: """
        status = ?
        AND retries < ?
      """,

      whereArgs: ["pending", 5],

      orderBy: "created_at ASC",
    );
  }

  // تحويل العملية إلى processing
  Future<void> markProcessing(int id) async {
    final database = await db.database;

    await database.update(
      "sync_queue",

      {"status": "processing"},

      where: "id=?",

      whereArgs: [id],
    );
  }

  // نجاح المزامنة
  Future<void> markAsSynced(int id) async {
    final database = await db.database;

    await database.update(
      "sync_queue",

      {"status": "completed"},

      where: "id=?",

      whereArgs: [id],
    );
  }

  // فشل الإرسال
  Future<void> markAsFailed(int id) async {
    final database = await db.database;

    await database.rawUpdate(
      """
      UPDATE sync_queue

      SET 
        retries = retries + 1,
        status = 'pending'

      WHERE id = ?
      """,

      [id],
    );
  }

  // حذف عملية
  Future<void> deleteById(int id) async {
    final database = await db.database;

    await database.delete("sync_queue", where: "id=?", whereArgs: [id]);
  }

  // تنظيف العمليات المكتملة
  Future<void> deleteCompleted() async {
    final database = await db.database;

    await database.delete(
      "sync_queue",

      where: "status=?",

      whereArgs: ["completed"],
    );
  }

  // عدد العمليات المنتظرة
  Future<int> countPending() async {
    final database = await db.database;

    final result = await database.rawQuery("""
      SELECT COUNT(*) as count
      FROM sync_queue
      WHERE status='pending'
      """);

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
