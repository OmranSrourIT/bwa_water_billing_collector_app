import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonRequestModel.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonResponse.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/failure_reason_service.dart';
import '../../auth/providers/auth_provider.dart';

final failureReasonServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);

  return FailureReasonService(dio: dio);
});

 final failureReasonProvider =
    FutureProvider.family<FailureReasonResponse, FailureReasonRequest>((ref, req) async {
  final service = ref.read(failureReasonServiceProvider);

  return service.sendFailureReason(
    invoiceNo: req.invoiceNo,
    failureReasonCode: req.code,
    failureNotes: req.notes,
    failureReason: req.failureReason,
    base64Image: req.base64,
  );
});
