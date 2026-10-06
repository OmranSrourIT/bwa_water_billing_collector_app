class PosInvoiceActionResponse {
  final bool isSuccess;
  final String invoiceNumber;
  final bool? isSentToPos;
  final String message;
  final int? statusCode;

  const PosInvoiceActionResponse({
    required this.isSuccess,
    required this.invoiceNumber,
    required this.isSentToPos,
    required this.message,
    this.statusCode,
  });

  factory PosInvoiceActionResponse.fromJson(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    final invoice = json['Invoice'];

    final invoiceMap = invoice is Map
        ? Map<String, dynamic>.from(invoice)
        : <String, dynamic>{};

    final rawFlag = invoiceMap['IsSentToPOS'];

    bool? isSentToPos;

    if (rawFlag is bool) {
      isSentToPos = rawFlag;
    } else if (rawFlag != null) {
      final value = rawFlag.toString().toLowerCase();

      if (value == 'true') {
        isSentToPos = true;
      } else if (value == 'false') {
        isSentToPos = false;
      }
    }

    final error = json['error'];

    final errorMap = error is Map
        ? Map<String, dynamic>.from(error)
        : <String, dynamic>{};

    return PosInvoiceActionResponse(
      isSuccess: invoiceMap.isNotEmpty && statusCode != 404,
      invoiceNumber: invoiceMap['InvoiceNumber']?.toString() ?? '',
      isSentToPos: isSentToPos,
      message: errorMap['message']?.toString() ?? '',
      statusCode: statusCode,
    );
  }
}

class PaymentStatusCheckResponse {
  final bool isPaid;
  final bool isVerified;
  final String field;
  final String arMessage;
  final String enMessage;
  final int? statusCode;

  const PaymentStatusCheckResponse({
    required this.isPaid,
    required this.isVerified,
    required this.field,
    required this.arMessage,
    required this.enMessage,
    this.statusCode,
  });

  factory PaymentStatusCheckResponse.fromJson(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    final field = json['field']?.toString() ?? '';

    final result = json['Result']?.toString().toLowerCase() ?? '';

    final isPaid =   field.toLowerCase() == 'paid' ||  result == 'paid' ;

    final isNotPaid = field.toLowerCase() == 'notpaid';

    return PaymentStatusCheckResponse(
      isPaid: isPaid,
      isVerified: isPaid || isNotPaid,
      field: field,
      arMessage: json['AR_message']?.toString() ?? '',
      enMessage: json['EN_message']?.toString() ?? '',
      statusCode: statusCode,
    );
  }
}
