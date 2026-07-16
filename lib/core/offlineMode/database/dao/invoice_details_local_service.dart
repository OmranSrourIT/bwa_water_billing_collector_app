import 'dart:convert';
import 'package:bwa_water_billing_collector_app/core/constants/attachment_type.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_attachment_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/lookup_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:sqflite/sqflite.dart';

class InvoiceDetailsLocalService {
  final AppDatabase db;
  final InvoiceAttachmentLocalService attachmentLocal;
  final LookupLocalService lookupLocal;
  InvoiceDetailsLocalService(this.db, this.attachmentLocal, this.lookupLocal);

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

      "invoice_details_json": jsonEncode(
        item.invoiceDetails
            .map(
              (e) => {
                "SequenceNo": e.sequenceNo,

                "Description": e.description,

                "Amount": e.amount,

                "AmountFormatted": e.amountFormatted,
              },
            )
            .toList(),
      ),

      "failure_reasons_json": jsonEncode(
        item.failureReasons
            .map(
              (e) => {
                "FailureReasonCode": e.failureReasonCode,
                "FailureNotes": e.failureNotes,
                "Attachment": null,
              },
            )
            .toList(),
      ),

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

      "activeCollectionPeriod": item.activeCollectionPeriod,

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

    final invoiceDetailsJson = json["invoice_details_json"] as String?;

    final failureReasonsJson = json["failure_reasons_json"] as String?;

    final lookupJson = json["lookup_json"] as String?;

    final meterAttachment = await attachmentLocal.getAttachment(
      invoiceNo: invoiceNo,
      type: AttachmentType.meter,
    );

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

      payment: json["payment_ref_no"] != null
          ? PaymentModel(
              paymentRefNo: json["payment_ref_no"] as int,
              paymentDate: json["payment_date"] != null
                  ? DateTime.parse(json["payment_date"] as String)
                  : null,
            )
          : null,

      invoiceDetails: invoiceDetailsJson == null
          ? []
          : (jsonDecode(invoiceDetailsJson) as List)
                .map((e) => InvoiceDetailModel.fromJson(e))
                .toList(),

      failureReasons: failureReasonsJson == null
          ? []
          : await Future.wait(
              (jsonDecode(failureReasonsJson) as List).map((e) async {
                final model = FieldFailureReasonModel.fromJson(e);

                final attachment = await attachmentLocal.getAttachment(
                  invoiceNo: invoiceNo,
                  type: AttachmentType.failure,
                  reasonCode: model.failureReasonCode,
                );

                return FieldFailureReasonModel(
                  failureReasonCode: model.failureReasonCode,
                  failureNotes: model.failureNotes,
                  attachment: attachment,
                );
              }),
            ),

      lookup: lookupJson == null
          ? []
          : (jsonDecode(lookupJson) as List)
                .map((e) => LookupModel.fromJson(e))
                .toList(),
      attachment: meterAttachment,

      periodFromDate: json["period_from_date"] != null
          ? DateTime.parse(json["period_from_date"] as String)
          : null,

      periodToDate: json["period_to_date"] != null
          ? DateTime.parse(json["period_to_date"] as String)
          : null,

      currentReadDateTime: json["current_read_date_time"] != null
          ? DateTime.parse(json["current_read_date_time"] as String)
          : null,

      previousReadingDateTime: json["previous_reading_date_time"] != null
          ? DateTime.parse(json["previous_reading_date_time"] as String)
          : null,

      installationDate: json["installation_date"] != null
          ? DateTime.parse(json["installation_date"] as String)
          : null,

      activeCollectionPeriod: json["activeCollectionPeriod"] as String,
      // attachment: json["attachment"] as String?,
    );
  }

  Future<void> updateReading({
    required String invoiceNo,
    required double currentReading,
    required DateTime currentReadDateTime,
  }) async {
    final database = await db.database;

    await database.update(
      "invoice_details",
      {
        "current_reading": currentReading,
        "current_read_date_time": currentReadDateTime.toIso8601String(),
      },
      where: "invoice_no = ?",
      whereArgs: [invoiceNo],
    );
  }

  Future<void> updateFailureReason({
    required String invoiceNo,
    required String code,
    required String notes,
    required String? attachment,
  }) async {
    final database = await db.database;

    await database.update(
      "invoice_details",
      {
        "failure_reasons_json": jsonEncode([
          {
            "FailureReasonCode": code,
            "FailureNotes": notes,
            "Attachment": attachment,
          },
        ]),
      },
      where: "invoice_no = ?",
      whereArgs: [invoiceNo],
    );
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
      "invoice_details",
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
      "invoice_details",
      {"lookup_json": jsonEncode(lookups)},
      where: "invoice_no = ?",
      whereArgs: [invoiceNo],
    );
  }
}
