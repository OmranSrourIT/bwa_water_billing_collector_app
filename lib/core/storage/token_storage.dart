import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _rememberKey = 'remember_me';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      throw Exception('Cannot save empty token');
    }

    await _storage.write(
      key: _tokenKey,
      value: cleanToken,
    );
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveRememberMe(bool value) async {
    await _storage.write(
      key: _rememberKey,
      value: value.toString(),
    );
  }

  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberKey);
    return value == 'true';
  }

  Future<void> saveUsername(String username) async {
    await _storage.write(
      key: _usernameKey,
      value: username,
    );
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  Future<void> savePassword(String password) async {
    await _storage.write(
      key: _passwordKey,
      value: password,
    );
  }

  Future<String?> getPassword() async {
    return await _storage.read(key: _passwordKey);
  }

  Future<void> clearRememberMe() async {
    await _storage.delete(key: _rememberKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
