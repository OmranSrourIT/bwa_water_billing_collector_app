import 'dart:convert';

import 'package:dio/dio.dart';

String handleDioError(DioException e) {
  final data = e.response?.data;

  if (data is Map) {
    if (data["error"]?["message"] != null) {
      return data["error"]["message"];
    }
    if (data["message"] != null) {
      return data["message"];
    }
  }

 if (data is String) {
  try {
    final json = jsonDecode(data);

    if (json["error"]?["message"] != null) {
      return json["error"]["message"];
    }

    if (json["message"] != null) {
      return json["message"];
    }

    return data;
  } catch (_) {
    return data;
  }
}

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return "انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.";

    case DioExceptionType.receiveTimeout:
    return "الخادم لا يستجيب حالياً. يرجى المحاولة مرة أخرى.";
    case DioExceptionType.connectionError:
 return "لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.";

    case DioExceptionType.badResponse:
      return "Server error (${e.response?.statusCode})";
    default:
  return e.message ?? "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.";
  }
}
