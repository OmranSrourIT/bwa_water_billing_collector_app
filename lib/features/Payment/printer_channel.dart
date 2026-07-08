import 'package:flutter/services.dart';

class PrinterChannel {
  static const MethodChannel _channel = MethodChannel('printer_channel');

  static Future<void> printImage({
    required String mac,
    required Uint8List image,
  }) async {
    await _channel.invokeMethod('printImage', {"mac": mac, "image": image});
  }

  static Future<List<Map<String, dynamic>>> getPairedPrinters() async {
    final result = await _channel.invokeMethod('getPairedPrinters');

    return (result as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
