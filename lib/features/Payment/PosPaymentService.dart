abstract class PosPaymentService {
  Future<PaymentResult> sale({
    required double amount,
    required String referenceId,
  });

  Future<void> activate(String activationCode);

  Future<void> warmUp();

  Future<bool> isInstalled();
}

class PaymentRequest {
  final String invoiceNo;
  final double amount;
  final String referenceId;

  PaymentRequest({
    required this.invoiceNo,
    required this.amount,
    required this.referenceId,
  });
}


class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? approvalCode;
  final String? rrn;
  final String? message;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.approvalCode,
    this.rrn,
    this.message,
  });
}
