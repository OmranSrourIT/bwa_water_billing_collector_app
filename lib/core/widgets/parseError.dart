import 'dart:convert';

String parseError(dynamic error) {
  const fallback = "حدث خطأ غير متوقع";

  try {
    // 1) DioException
    if (error.toString().contains("DioException")) {
      final data = (error as dynamic).response?.data;

      if (data is Map) {
        return data["error"]?["message"] ??
            data["message"] ??
            fallback;
      }

      if (data is String) {
        final decoded = jsonDecode(data);
        return decoded["error"]?["message"] ??
            decoded["message"] ??
            fallback;
      }
    }

    // 2) Normal Exception (حالتك الحالية)
    final text = error.toString();

    final jsonStart = text.indexOf("{");
    final jsonEnd = text.lastIndexOf("}");

    if (jsonStart != -1 && jsonEnd != -1) {
      final jsonString = text.substring(jsonStart, jsonEnd + 1);
      final decoded = jsonDecode(jsonString);

      return decoded["error"]?["message"] ??
          decoded["message"] ??
          fallback;
    }

    return text;
  } catch (_) {
    return fallback;
  }
}
