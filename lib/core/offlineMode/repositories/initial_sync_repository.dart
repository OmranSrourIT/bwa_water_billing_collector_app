import 'package:bwa_water_billing_collector_app/core/constants/attachment_type.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/AccountLocalService.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/batch_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_attachment_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_details_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/lookup_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/storage/image_storage_service.dart';
import 'package:bwa_water_billing_collector_app/features/Account/services/account_api_service.dart';
import 'package:bwa_water_billing_collector_app/features/batch/services/batch_Api_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/FieldFailureLookupService.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoice_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoiceDetials_service.dart';

import '../database/dao/invoice_local_service.dart';

class InitialSyncRepository {
  final BatchApiService batchApi;
  final InvoiceService invoiceApi;
  final InvoiceDetailsService detailsApi;
  final FieldFailureLookupService lookupApi;
  final AccountApiService accountApi;
  final BatchLocalService batchLocal;
  final InvoiceLocalService invoiceLocal;
  final InvoiceDetailsLocalService detailsLocal;
  final LookupLocalService lookupLocal;
  final InvoiceAttachmentLocalService attachmentLocal;
  final ImageStorageService imageStorage;
  final AccountLocalService accountLocal;

  InitialSyncRepository({
    required this.batchApi,
    required this.invoiceApi,
    required this.detailsApi,
    required this.lookupApi,
    required this.accountApi,
    required this.batchLocal,
    required this.invoiceLocal,
    required this.detailsLocal,
    required this.lookupLocal,
    required this.attachmentLocal,
    required this.imageStorage,
    required this.accountLocal,
  });

  Future<void> downloadInitialData({
    Function(String message)? onProgress,
  }) async {
    try {
      onProgress?.call("جاري تجهيز البيانات محليا...");

      final account = await accountApi.getAccount();

      await accountLocal.saveAccount(account);

      final batches = await batchApi.getBatches();

      await batchLocal.insertBatches(batches);

      const lookupTypes = ["FieldFailureReason", "InvoiceStatus"];

      for (final type in lookupTypes) {
        final lookups = await lookupApi.getLookupStatus(type);

        await lookupLocal.insertLookups(type, lookups);
      }
      for (final batch in batches) {
        final invoices = await invoiceApi.getInvoices(batch.batchNumber);
        await invoiceLocal.insertInvoices(batch.batchNumber, invoices);

        for (final invoice in invoices) {
          final details = await detailsApi.getInvoice(invoice.invoiceNo);
          await _saveAttachments(details);

          await detailsLocal.insertInvoiceDetails(details);
        }
      }

      onProgress?.call("تم تحميل جميع البيانات بنجاح");
    } catch (e) {
      onProgress?.call("حدث خطأ أثناء تحميل البيانات");

      rethrow;
    }
  }

  Future<void> _saveAttachments(InvoiceInformationModel details) async {
    // صورة قراءة العداد

    if (details.attachment != null && details.attachment!.isNotEmpty) {
      final path = await imageStorage.saveInvoiceImage(
        invoiceNo: details.invoiceNumber,
        type: AttachmentType.meter,
        base64: details.attachment,
      );

      if (path != null) {
        final existing = await attachmentLocal.getAttachment(
          invoiceNo: details.invoiceNumber,
          type: AttachmentType.meter,
        );

        if (existing == null) {
          await attachmentLocal.saveAttachment(
            invoiceNo: details.invoiceNumber,
            type: AttachmentType.meter,
            path: path,
          );
        }
      }
    }

    // صور التعذر

    for (final reason in details.failureReasons) {
      if (reason.attachment == null || reason.attachment!.isEmpty) {
        continue;
      }

      final path = await imageStorage.saveInvoiceImage(
        invoiceNo: details.invoiceNumber,
        type: AttachmentType.failure,
        base64: reason.attachment,
      );

      if (path != null) {
        final existing = await attachmentLocal.getAttachment(
          invoiceNo: details.invoiceNumber,
          type: AttachmentType.failure,
          reasonCode: reason.failureReasonCode,
        );

        if (existing == null) {
          await attachmentLocal.saveAttachment(
            invoiceNo: details.invoiceNumber,
            type: AttachmentType.failure,
            reasonCode: reason.failureReasonCode,
            path: path,
          );
        }
      }
    }
  }
}
