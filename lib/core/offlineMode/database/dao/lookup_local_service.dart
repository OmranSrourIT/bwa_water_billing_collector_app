import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/field_failure_lookup_model.dart';
import 'package:sqflite/sqflite.dart';

class LookupLocalService {
  final AppDatabase db;

  LookupLocalService(this.db);

  Future<void> insertLookups(
    String lookupType,
    List<FieldFailureLookupModel> items,
  ) async {
    final database = await db.database;

    final batch = database.batch();

    for (final item in items) {
      batch.insert(
        "lookups",
        {
          "lookup_type": lookupType,
          "code": item.code,
          "ar_desc": item.arDesc,
          "en_desc": item.enDesc,
          "order_no": item.order,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<FieldFailureLookupModel>> getLookups(
    String lookupType,
  ) async {
    final database = await db.database;
    final result = await database.query(
      "lookups",
      where: "lookup_type=?",
      whereArgs: [lookupType],
      orderBy: "order_no ASC",
    );

    return result
        .map(
          (e) => FieldFailureLookupModel(
            code: e["code"] as String,
            arDesc: e["ar_desc"] as String? ?? "",
            enDesc: e["en_desc"] as String? ?? "",
            order: e["order_no"] as int?,
          ),
        )
        .toList();
  }

  Future<FieldFailureLookupModel?> getLookupByCode({
  required String lookupType,
  required String code,
}) async {
  final database = await db.database;

  final result = await database.query(
    "lookups",
    where: "lookup_type = ? AND code = ?",
    whereArgs: [lookupType, code],
    limit: 1,
  );

  if (result.isEmpty) {
    return null;
  }

  final item = result.first;

  return FieldFailureLookupModel(
    code: item["code"] as String,
    arDesc: item["ar_desc"] as String? ?? "",
    enDesc: item["en_desc"] as String? ?? "",
    order: item["order_no"] as int?,
  );
}
}
