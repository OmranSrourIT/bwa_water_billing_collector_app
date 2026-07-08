import 'dart:convert';

class BatchEndResponse {
  final String result;
  final String arMessage;
  final String enMessage;
  final String? code;

  const BatchEndResponse({
    required this.result,
    required this.arMessage,
    required this.enMessage,
    this.code,
  });

 
  bool get isSuccess => result.toLowerCase() == "success";

  factory BatchEndResponse.fromJson(Map<String, dynamic> json) {
 
    if (json.containsKey('error') && json['error'] is Map) {
      final err = json['error'] as Map<String, dynamic>;
      final msg = err["message"] ?? "خطأ غير معروف";
      return BatchEndResponse(
        result: "Error",
        arMessage: err["AR_message"] ?? msg,
        enMessage: err["EN_message"] ?? msg,
        code: err["code"]?.toString(),
      );
    }
 
    final String res = (json["Result"] ?? "Error").toString();
    
 
    final String ar = json["AR_message"] ?? json["message"] ?? "لا توجد رسالة من السيرفر";
    final String en = json["EN_message"] ?? json["message"] ?? "No message from server";

    return BatchEndResponse(
      result: res,
      arMessage: ar,
      enMessage: en,
      code: json["code"]?.toString(),
    );
  }

  /// مصنع لإنشاء استجابة خطأ مخصصة
  factory BatchEndResponse.error(String ar, String en, {String? code}) =>
      BatchEndResponse(
        result: "Error",
        arMessage: ar,
        enMessage: en,
        code: code,
      );

  /// مصنع لأخطاء الشبكة
  factory BatchEndResponse.networkError() => const BatchEndResponse(
        result: "Error",
        arMessage: "فشل الاتصال بالخادم، يرجى التأكد من الإنترنت",
        enMessage: "Server connection failed, please check your internet",
      );
}
