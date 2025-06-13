import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static final AuthStorage _instance = AuthStorage._internal();
  factory AuthStorage() => _instance;
  AuthStorage._internal();

  final _storage = FlutterSecureStorage();

  static const _keyToken = 'auth_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }
}
