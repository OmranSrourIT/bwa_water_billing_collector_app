import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrinterStorage {
  static const _key = "printer_mac";
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveMac(String mac) async {
    await _storage.write(key: _key, value: mac);
  }

  static Future<String?> getMac() async {
    return await _storage.read(key: _key);
  }
}
