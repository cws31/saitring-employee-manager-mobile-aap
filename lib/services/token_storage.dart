import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('Token cannot be empty.');
    }

    await _storage.write(key: _tokenKey, value: token);
  }

 
  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }


  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
