import 'dart:convert';

import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/lookup_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoice_model.dart';
import 'package:sqflite/sqflite.dart';

class InvoiceLocalService {
  final AppDatabase db;
  final LookupLocalService lookupLocal;
  InvoiceLocalService(this.db, this.lookupLocal);

  Future<void> insertInvoices(
    String batchNumber,
    List<InvoiceModel> invoices,
  ) async {
    final database = await db.database;

    final batch = database.batch();

    for (final item in invoices) {
      batch.insert("invoices", {
        "invoice_no": item.invoiceNo,

        "batch_number": batchNumber,

        "account_no": item.accountNo,

        "customer_name": item.customerName,

        "address": item.address,

        "usage_type": item.usageType,

        "collector_name": item.collectorName,

        "total_amount": item.totalAmount,

        "consumption_qty_row": item.consumptionQtyRow,

        "consumption_qty_potable": item.consumptionQtyPotable,

        "is_notified": item.isNotified ? 1 : 0,

        "is_meter_rollover": item.isMeterRollover ? 1 : 0,

        // Payment كامل
        "payment_json": item.payment == null
            ? null
            : jsonEncode({
                "PaymentRefNo": item.payment!.paymentRefNo,

                "PaymentDate": item.payment!.paymentDate?.toIso8601String(),
              }),

        // Lookup كامل
        "lookup_json": jsonEncode(
          item.lookup
              .map(
                (e) => {
                  "LookupType": e.lookupType,

                  "Code": e.code,

                  "ArDesc": e.arDesc,

                  "EnDesc": e.enDesc,
                },
              )
              .toList(),
        ),

        "synced": 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<InvoiceModel>> getInvoices(String batchNumber) async {
    final database = await db.database;

    final result = await database.rawQuery(
      "SELECT * FROM invoices WHERE batch_number = ?",
      [batchNumber],
    );

    
    return result.map((json) {
      final lookupJson = json["lookup_json"] as String?;

      final paymentJson = json["payment_json"] as String?;

      return InvoiceModel(
        invoiceNo: json["invoice_no"] as String,

        accountNo: json["account_no"] as String? ?? "",

        customerName: json["customer_name"] as String? ?? "",

        address: json["address"] as String? ?? "",

        usageType: json["usage_type"] as String? ?? "",

        collectorName: json["collector_name"] as String? ?? "",

        totalAmount: (json["total_amount"] as num? ?? 0).toDouble(),

        isNotified: json["is_notified"] == 1,

        isMeterRollover: json["is_meter_rollover"] == 1,

        consumptionQtyRow: (json["consumption_qty_row"] as num? ?? 0)
            .toDouble(),

        consumptionQtyPotable: (json["consumption_qty_potable"] as num? ?? 0)
            .toDouble(),

        lookup: lookupJson == null
            ? []
            : (List<Map<String, dynamic>>.from(
                jsonDecode(lookupJson),
              )).map((e) => LookupModelParent.fromJson(e)).toList(),

        payment: paymentJson == null
            ? null
            : PaymentModel.fromJson(jsonDecode(paymentJson)),
      );
    }).toList();
  }

  Future<void> updateInvoiceStatus({
    required String invoiceNo,
    required String status,
  }) async {
    final database = await db.database;

    final statusLookup = await lookupLocal.getLookupByCode(
      lookupType: "InvoiceStatus",
      code: status,
    );

    if (statusLookup == null) return;

    final result = await database.query(
      "invoices",
      columns: ["lookup_json"],
      where: "invoice_no = ?",
      whereArgs: [invoiceNo],
    );

    if (result.isEmpty) return;

    final lookupJson = result.first["lookup_json"] as String?;

    if (lookupJson == null || lookupJson.isEmpty) return;

    final List<dynamic> lookups = jsonDecode(lookupJson);

    for (final item in lookups) {
      if (item["LookupType"] == "InvoiceStatus") {
        item["Code"] = statusLookup.code;
        item["ArDesc"] = statusLookup.arDesc;
        item["EnDesc"] = statusLookup.enDesc;
        break;
      }
    }

    await database.update(
      "invoices",
      {"lookup_json": jsonEncode(lookups)},
      where: "invoice_no = ?",
      whereArgs: [invoiceNo],
    );
  }
}
