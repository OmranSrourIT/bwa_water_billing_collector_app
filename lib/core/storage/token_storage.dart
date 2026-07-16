import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = "auth_token";
  static const _rememberKey = "remember_me";
  static const _usernameKey = "username";
  static const _passwordKey = "password";

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  //================ TOKEN =================//

  Future<void> saveToken(String token) async {
    await storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await storage.delete(key: _tokenKey);
  }

  //================ REMEMBER ME =================//

  Future<void> saveRememberMe(bool value) async {
    await storage.write(
      key: _rememberKey,
      value: value.toString(),
    );
  }

  Future<bool> getRememberMe() async {
    final value = await storage.read(key: _rememberKey);

    return value == "true";
  }

  Future<void> saveUsername(String username) async {
    await storage.write(
      key: _usernameKey,
      value: username,
    );
  }
  Future<void> savePassword(String password) async {
  await storage.write(
    key: _passwordKey,
    value: password,
  );
}

Future<String?> getPassword() async {
  return storage.read(key: _passwordKey);
}

  Future<String?> getUsername() async {
    return storage.read(key: _usernameKey);
  }

Future<void> clearRememberMe() async {
  await storage.delete(key: _rememberKey);
  await storage.delete(key: _usernameKey);
  await storage.delete(key: _passwordKey);
}
  Future<void> clearAll() async {
    await storage.deleteAll();
  }
}
