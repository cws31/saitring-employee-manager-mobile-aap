import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'access_token';
  static const String _ownerIdKey = 'owner_id';

  static Future<void> saveSession({
    required String token,
    required String ownerId,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _ownerIdKey, value: ownerId);
  }

  static Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<String?> readOwnerId() async {
    return _storage.read(key: _ownerIdKey);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _ownerIdKey);
  }
}
