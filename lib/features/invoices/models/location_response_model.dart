class LocationResponse {
  final bool isSuccess;
  final String? result;
  final String? errorCode;
  final String? errorMessage;

  const LocationResponse({
    required this.isSuccess,
    this.result,
    this.errorCode,
    this.errorMessage,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    // Success
    if (json["Result"] != null) {
      return LocationResponse(
        isSuccess: json["Result"].toString().toLowerCase() == "success",
        result: json["Result"].toString(),
      );
    }

    // Error
    final error = json["error"];

    if (error is Map) {
      return LocationResponse(
        isSuccess: false,
        errorCode: error["code"]?.toString(),
        errorMessage: error["message"]?.toString(),
      );
    }

    return const LocationResponse(
      isSuccess: false,
      errorMessage: "Unexpected response",
    );
  }

  factory LocationResponse.success(Map<String, dynamic> json) {
    return LocationResponse(
      isSuccess: true,
      result: json["Result"]?.toString(),
    );
  }

  factory LocationResponse.error(Map<String, dynamic> json) {
    final error = json["error"];

    return LocationResponse(
      isSuccess: false,
      errorCode: error is Map
          ? error["code"]?.toString()
          : null,
      errorMessage: error is Map
          ? error["message"]?.toString()
          : null,
    );
  }
}
