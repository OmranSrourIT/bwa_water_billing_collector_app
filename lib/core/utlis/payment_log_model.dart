class PaymentLogModel {
  final String? tranId;

  final String posMessageId;

  final String status;

  final String rspCode;

  final String rspMsg;

  final String totalAmount;

  final String? approvalCode;

  final String? rrn;

  final String? paymentMethod;

  final String? maskedAccount;

  final String createdAt;

  final String? tranType;

  final String? entryMode;

  PaymentLogModel({
    this.tranId,

    required this.posMessageId,

    required this.status,

    required this.rspCode,

    required this.rspMsg,

    required this.totalAmount,

    this.approvalCode,

    this.rrn,

    this.paymentMethod,

    this.maskedAccount,

    required this.createdAt,

    this.tranType,

    this.entryMode,
  });

  Map<String, dynamic> toJson() {
    return {
      "tranId": tranId,

      "posMessageId": posMessageId,

      "status": status,

      "rspCode": rspCode,

      "rspMsg": rspMsg,

      "totalAmount": totalAmount,

      "approvalCode": approvalCode,

      "rrn": rrn,

      "paymentMethod": paymentMethod,

      "maskedAccount": maskedAccount,

      "createdAt": createdAt,

      "tranType": tranType,

      "entryMode": entryMode,
    };
  }
}
