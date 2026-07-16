import 'dart:convert';

import 'package:bwa_water_billing_collector_app/core/storage/image_storage_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/reading_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/failure_reason_service.dart';

import '../database/dao/sync_queue_local_service.dart';

class SyncEngine {
  final SyncQueueLocalService queue;
  final ReadingService readingService;
  final FailureReasonService failureReasonService;
  final ImageStorageService imageStorage;

  SyncEngine({
    required this.queue,
    required this.readingService,
    required this.failureReasonService,
    required this.imageStorage,
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
        await queue.markAsFailed(id);
        allSuccess = false;
      }
    }

    return allSuccess;
  }

  Future<bool> _syncReading(Map<String, dynamic> data) async {
    final base64 = await imageStorage.imageToBase64(
      data["imagePath"] as String?,
    );

    final response = await readingService.insertReading(
      invoiceNumber: data["invoiceNumber"],

      previousReading: (data["previousReading"] ?? 0).toDouble(),

      currentReading: (data["currentReading"] ?? 0).toDouble(),

      currentReadDateTime: data["currentReadDateTime"],

      previousReadingDateTime: data["previousReadingDateTime"],

      isMeterRollover: data["isMeterRollover"] ?? false,

      latitude: data["latitude"],

      longitude: data["longitude"],

      // نحول الـ Path إلى Base64 قبل الإرسال
      base64: base64,
    );

    return response.isSuccess;
  }

  Future<bool> _syncFailureReason(Map<String, dynamic> data) async {

      final base64 = await imageStorage.imageToBase64(
    data["imagePath"] as String?,
  );


    final response = await failureReasonService.sendFailureReason(
      invoiceNo: data["invoiceNo"],

      failureReasonCode: data["code"],

      failureNotes: data["notes"],

      failureReason: data["failureReason"],

      base64Image:base64,
    );

    return response.result == "Success";
  }

  Future<bool> _syncUpdateInvoiceStatus(Map<String, dynamic> data) async {
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
