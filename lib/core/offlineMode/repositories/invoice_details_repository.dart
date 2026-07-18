import 'package:bwa_water_billing_collector_app/core/constants/attachment_type.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_attachment_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_details_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/storage/image_storage_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoiceDetials_service.dart';

class InvoiceDetailsRepository {
  final InvoiceDetailsService api;

  final InvoiceDetailsLocalService local;
  final InvoiceAttachmentLocalService attachmentLocal;
  final ImageStorageService imageStorage;

  final bool isOnline;

  InvoiceDetailsRepository({
    required this.api,
    required this.local,
    required this.attachmentLocal,
    required this.imageStorage,
    required this.isOnline,
  });

  Future<InvoiceInformationModel> getInvoice(String invoiceNo) async {
    if (isOnline) {
      final result = await api.getInvoice(invoiceNo);
      await _saveAttachments(result);

      await local.insertInvoiceDetails(result);
      return result;
    }

    final localData = await local.getInvoiceDetails(invoiceNo);

    if (localData == null) {
      throw Exception("No offline data");
    }

    return localData;
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
