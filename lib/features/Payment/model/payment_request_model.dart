class PaymentRequest {
  final String invoiceNo;
  final String tranId;
  final String trace;
  final String rrn;
  final String tranType;
  final String tranStatus;
  final String approvalCode;
  final String paymentMethod;
  final String entryMode;
  final String maskedAccount;
  final String cvmPerformed;
  final String acqMid;
  final String acqTid;
  final String posMessageId;
  final String mchAddress;
  final String mchName;
  final double totalAmount;
  final String createByName;
  final String createdAt;
  final String updatedAt;
  final double amount;
  final String description;

  PaymentRequest({
    required this.invoiceNo,
    required this.tranId,
    required this.trace,
    required this.rrn,
    required this.tranType,
    required this.tranStatus,
    required this.approvalCode,
    required this.paymentMethod,
    required this.entryMode,
    required this.maskedAccount,
    required this.cvmPerformed,
    required this.acqMid,
    required this.acqTid,
    required this.posMessageId,
    required this.mchAddress,
    required this.mchName,
    required this.totalAmount,
    required this.createByName,
    required this.createdAt,
    required this.updatedAt,
    required this.amount,
    required this.description,
  });
}
