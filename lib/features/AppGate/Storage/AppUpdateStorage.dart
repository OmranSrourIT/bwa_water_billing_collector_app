import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppUpdateStorage {
  static const _keyNeedUpdate = "need_update";
  static const _keyApkUrl = "apk_url";
  static const _keyLastCheck = "update_last_check";

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> saveUpdateData({
    required bool needUpdate,
    required String apkUrl,
  }) async {
    await storage.write(key: _keyNeedUpdate, value: needUpdate.toString());
    await storage.write(key: _keyApkUrl, value: apkUrl);
    await storage.write(key: _keyLastCheck,  value: DateTime.now().toIso8601String(),);
  }

  Future<bool> getNeedUpdate() async {
    final value = await storage.read(key: _keyNeedUpdate);
    return value == "true";
  }

  Future<String?> getApkUrl() async {
    return await storage.read(key: _keyApkUrl);
  }

  Future<DateTime?> getLastCheck() async {
    final value = await storage.read(key: _keyLastCheck);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> clear() async {
    await storage.delete(key: _keyNeedUpdate);
    await storage.delete(key: _keyApkUrl);
    await storage.delete(key: _keyLastCheck);
  }
}
