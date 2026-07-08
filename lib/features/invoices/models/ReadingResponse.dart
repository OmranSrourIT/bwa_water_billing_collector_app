class ReadingResponse {

  final bool isSuccess;

  final String result;

  final String arMessage;

  final String enMessage;

  ReadingResponse({
    required this.isSuccess,
    required this.result,
    required this.arMessage,
    required this.enMessage,
  });

  factory ReadingResponse.success(Map<String,dynamic> json){

    return ReadingResponse(
      isSuccess: true,
      result: json["Result"] ?? "",
      arMessage: json["AR_message"] ?? "",
      enMessage: json["EN_message"] ?? "",
    );
  }

  factory ReadingResponse.error(Map<String,dynamic> json){

    return ReadingResponse(
      isSuccess: false,
      result: "Error",
      arMessage: json["AR_message"] ?? "",
      enMessage: json["EN_message"] ?? "",
    );
  }
}
