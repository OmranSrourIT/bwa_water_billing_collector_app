import 'package:bwa_water_billing_collector_app/features/Payment/model/pos_payment_models.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/services/pos_payment_service.dart';

class PosPaymentRepository {
  final PosPaymentService api;

  PosPaymentRepository({required this.api});

  Future<PosInvoiceActionResponse> reserveInvoice({
    required String invoiceNo,
    required String posReference,
  }) {
    return api.reserveInvoice(invoiceNo: invoiceNo, posReference: posReference);
  }

  Future<PosInvoiceActionResponse> releaseInvoice({required String invoiceNo}) {
    return api.releaseInvoice(invoiceNo: invoiceNo);
  }

  Future<PaymentStatusCheckResponse> checkPayment({required String invoiceNo}) {
    return api.checkPayment(invoiceNo: invoiceNo);
  }
}
