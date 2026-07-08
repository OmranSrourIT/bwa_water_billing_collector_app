import 'package:bwa_water_billing_collector_app/features/invoices/models/ReadingResponse.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

import '../models/reading_request_model.dart';

import '../services/reading_service.dart';

final readingServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);

  return ReadingService(dio: dio);
});

final insertReadingProvider = FutureProvider.family<ReadingResponse, ReadingRequest>((
  ref,
  req,
) async {
  final service = ref.read(readingServiceProvider);

  return service.insertReading(
    invoiceNumber: req.invoiceNumber,

    previousReading: req.previousReading.toDouble(),

    currentReading: req.currentReading.toDouble(),

    currentReadDateTime: req.currentReadDateTime,

    previousReadingDateTime: req.previousReadingDateTime,

    isMeterRollover: req.isMeterRollover,

    latitude: req.latitude,

    longitude: req.longitude,

    base64: req.base64,
  );
});

final updateInvoiceStatusProvider =
    FutureProvider.family<String, ({String invoiceNo, String status})>((
      ref,
      request,
    ) async {
      final service = ref.read(readingServiceProvider);

      return service.updateInvoiceStatus(
        invoiceNumber: request.invoiceNo,
        status: request.status,
      );
    });
