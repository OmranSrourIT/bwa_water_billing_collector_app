import 'package:flutter/services.dart';

class MineSecService {
  static const _channel = MethodChannel('minesec/payment');

  static Function(String, dynamic)? _callback;

  static void init(Function(String, dynamic) onResult) {
    _callback = onResult;

    _channel.setMethodCallHandler((call) async {
      if (call.method == "paymentResult") {
        final data = Map<String, dynamic>.from(call.arguments);

        final code = data["rspCode"];

        if (code == "00") {
          _callback?.call("success", data);
        } else {
          _callback?.call("failed", data);
        }
      }
    });
  }

  static Future startPayment({
    required double amount,
    required String referenceId,
  }) async {
    return await _channel.invokeMethod("startPayment", {
      "amount": amount, 
      "referenceId": referenceId,
    });
  }
}
