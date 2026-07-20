class PaymentResponse {
  final bool isSuccess;

  final String result;

  final String arMessage;

  final String enMessage;

  PaymentResponse({
    required this.isSuccess,
    required this.result,
    required this.arMessage,
    required this.enMessage,
  });

  factory PaymentResponse.success(Map<String, dynamic> json) {
    return PaymentResponse(
      isSuccess: true,
      result: json["Result"] ?? "",
      arMessage: json["AR_message"] ?? "",
      enMessage: json["EN_message"] ?? "",
    );
  }

  factory PaymentResponse.error(Map<String, dynamic> json) {
    return PaymentResponse(
      isSuccess: false,
      result: "Error",
      arMessage: json["AR_message"] ?? "",
      enMessage: json["EN_message"] ?? "",
    );
  }
}
