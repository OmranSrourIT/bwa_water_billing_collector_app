import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoice_model.dart';
import 'package:sqflite/sqflite.dart';

class InvoiceLocalService {
  final AppDatabase db;

  InvoiceLocalService(this.db);

  Future<void> insertInvoices(
    String batchNumber,
    List<InvoiceModel> invoices,
  ) async {
    final database = await db.database;

    final batch = database.batch();

    for (final item in invoices) {
      final status = item.lookup
          .where((e) => e.lookupType == "InvoiceStatus")
          .firstOrNull
          ?.code;

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

        "payment_ref_no": item.payment?.paymentRefNo,
        "payment_date": item.payment?.paymentDate?.toIso8601String(),

        "invoice_status": status,

        "synced": 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<InvoiceModel>> getInvoices(String batchNumber) async {
    final database = await db.database;

    final result = await database.query(
      "invoices",
      where: "batch_number = ?",
      whereArgs: [batchNumber],
    );

    return result.map((json) {
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

        payment: null,

        lookup: [],
      );
    }).toList();
  }
}
