import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = "auth_token";

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await storage.write(key: _key, value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: _key);
  }

  Future<void> clearToken() async {
    await storage.delete(key: _key);

    // احتياط قوي (مهم لبعض الأجهزة)
    await storage.deleteAll();
  }
}
