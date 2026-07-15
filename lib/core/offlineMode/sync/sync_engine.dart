import 'dart:convert';

import 'package:bwa_water_billing_collector_app/features/invoices/services/reading_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/failure_reason_service.dart';

import '../database/dao/sync_queue_local_service.dart';

class SyncEngine {
  final SyncQueueLocalService queue;
  final ReadingService readingService;
  final FailureReasonService failureReasonService;

  SyncEngine({
    required this.queue,
    required this.readingService,
    required this.failureReasonService,
  });

  Future<bool> sync() async {
    final items = await queue.getPendingItems();

    bool allSuccess = true;

    for (final item in items) {
      final id = item["id"] as int;

      try {
        await queue.markProcessing(id);

        final type = item["type"] as String;

        final payload = jsonDecode(item["payload"] as String);

        bool success = false;

        switch (type) {
          case "READING":
            success = await _syncReading(payload);
            break;

          case "FAILURE_REASON":
            success = await _syncFailureReason(payload);
            break;

          case "UPDATE_INVOICE_STATUS":
            success = await _syncUpdateInvoiceStatus(payload);
            break;

          default:
            print("Unknown sync type => $type");
            success = true;
            break;
        }

        if (success) {
          await queue.markAsSynced(id);
        } else {
          await queue.markAsFailed(id);
          allSuccess = false;
        }
      } catch (e) {
        print("SYNC ERROR => $e");

        await queue.markAsFailed(id);
        allSuccess = false;
      }
    }

    return allSuccess;
  }

  

  Future<bool> _syncReading(Map<String, dynamic> data) async {
    final response = await readingService.insertReading(
      invoiceNumber: data["invoiceNumber"],

      previousReading: (data["previousReading"] ?? 0).toDouble(),

      currentReading: (data["currentReading"] ?? 0).toDouble(),

      currentReadDateTime: data["currentReadDateTime"],

      previousReadingDateTime: data["previousReadingDateTime"],

      isMeterRollover: data["isMeterRollover"] ?? false,

      latitude: data["latitude"],

      longitude: data["longitude"],

      base64: data["base64"],
    );

    return response.isSuccess;
  }

  Future<bool> _syncFailureReason(Map<String, dynamic> data) async {
    final response = await failureReasonService.sendFailureReason(
      invoiceNo: data["invoiceNo"],

      failureReasonCode: data["code"],

      failureNotes: data["notes"],

      failureReason: data["failureReason"],

      base64Image: data["base64"],
    );

    return response.result == "Success";
  }


Future<bool> _syncUpdateInvoiceStatus(
  Map<String, dynamic> data,
) async {
  try {
    final result = await readingService.updateInvoiceStatus(
      invoiceNumber: data["invoiceNo"],
      status: data["status"],
    );

    return result == "Invoice status updated";
  } catch (_) {
    return false;
  }
}
}
