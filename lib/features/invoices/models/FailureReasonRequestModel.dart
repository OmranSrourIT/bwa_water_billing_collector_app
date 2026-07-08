class FailureReasonRequest {
  final String invoiceNo;
  final String code;
  final String notes;
  final String failureReason; // 👈 مهم
  final String? base64;

  FailureReasonRequest({
    required this.invoiceNo,
    required this.code,
    required this.notes,
    required this.failureReason,
    this.base64,
  });
}
