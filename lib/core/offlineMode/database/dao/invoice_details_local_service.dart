import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:sqflite/sqflite.dart';

class InvoiceDetailsLocalService {
  final AppDatabase db;

  InvoiceDetailsLocalService(this.db);

  Future<void> insertInvoiceDetails(InvoiceInformationModel item) async {
    final database = await db.database;

    await database.insert("invoice_details", {
      "invoice_no": item.invoiceNumber,

      "period_from_date": item.periodFromDate?.toIso8601String(),

      "period_to_date": item.periodToDate?.toIso8601String(),

      "customer_name": item.customerName,

      "property_address": item.propertyAddress,

      "customer_mobile_no": item.customerMobileNo,

      "usage_type_name": item.usageTypeName,

      "invoice_type_name": item.invoiceTypeName,

      "collector_name": item.collectorName,

      "previous_reading": item.previousReading,

      "current_reading": item.currentReading,

      "current_read_date_time": item.currentReadDateTime?.toIso8601String(),

      "previous_reading_date_time": item.previousReadingDateTime
          ?.toIso8601String(),

      "total_invoice_amount": item.totalInvoiceAmount,

      "total_invoice_amount_calculated": item.totalInvoiceAmountCalculated,

      "account_no": item.accountNo,

      "estimated_potable_water": item.estimatedPotableWater,

      "estimated_raw_water": item.estimatedRawWater,

      "consumption_qty_row": item.consumptionQtyRow,

      "consumption_qty_potable": item.consumptionQtyPotable,

      "customer_id": item.customerID,

      "cycle_code": item.cycleCode,

      "region": item.region,

      "installation_date": item.installationDate?.toIso8601String(),

      "collection_period_description": item.collectionPeriodDescription,

      "payment_ref_no": item.payment?.paymentRefNo,

      "payment_date": item.payment?.paymentDate?.toIso8601String(),

      "attachment": item.attachment,

      "synced": 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<InvoiceInformationModel?> getInvoiceDetails(String invoiceNo) async {
    final database = await db.database;

    final result = await database.query(
      "invoice_details",
      where: "invoice_no = ?",
      whereArgs: [invoiceNo],
    );

    if (result.isEmpty) {
      return null;
    }

    final json = result.first;

    return InvoiceInformationModel(
      invoiceNumber: json["invoice_no"] as String,

      customerName: json["customer_name"] as String? ?? "",

      propertyAddress: json["property_address"] as String? ?? "",

      customerMobileNo: json["customer_mobile_no"] as String? ?? "",

      usageTypeName: json["usage_type_name"] as String? ?? "",

      invoiceTypeName: json["invoice_type_name"] as String? ?? "",

      collectorName: json["collector_name"] as String? ?? "",

      previousReading: (json["previous_reading"] as num? ?? 0).toDouble(),

      currentReading: (json["current_reading"] as num? ?? 0).toDouble(),

      totalInvoiceAmount: (json["total_invoice_amount"] as num? ?? 0)
          .toDouble(),

      totalInvoiceAmountCalculated:
          json["total_invoice_amount_calculated"] as String? ?? "",

      accountNo: json["account_no"] as String? ?? "",

      estimatedPotableWater: (json["estimated_potable_water"] as num? ?? 0)
          .toDouble(),

      estimatedRawWater: (json["estimated_raw_water"] as num? ?? 0).toDouble(),

      consumptionQtyRow: (json["consumption_qty_row"] as num? ?? 0).toDouble(),

      consumptionQtyPotable: (json["consumption_qty_potable"] as num? ?? 0)
          .toDouble(),

      customerID: json["customer_id"] as String? ?? "",

      cycleCode: json["cycle_code"] as int? ?? 0,

      region: json["region"] as String? ?? "",

      collectionPeriodDescription:
          json["collection_period_description"] as String? ?? "",

      invoiceDetails: [],

      failureReasons: [],

      lookup: [],

      attachment: json["attachment"] as String?,
    );
  }
}
