class FailureReasonResponse {
  final String result;
  final String arMessage;
  final String enMessage;

  FailureReasonResponse({
    required this.result,
    required this.arMessage,
    required this.enMessage,
  });

  factory FailureReasonResponse.fromJson(Map<String, dynamic> json) {
    return FailureReasonResponse(
      result: json["Result"] ?? "",
      arMessage: json["AR_message"] ?? "",
      enMessage: json["EN_message"] ?? "",
    );
  }
}
