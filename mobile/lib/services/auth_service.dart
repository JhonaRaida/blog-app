import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_client.dart';

/// Registro, inicio de sesión y almacenamiento seguro del token.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;
  // El token se guarda cifrado (Keystore en Android / Keychain en iOS).
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'access_token';

  Future<User> login(String email, String password) async {
    final data = await _api.post('/auth/login', {'email': email, 'password': password});
    return _saveSession(data);
  }

  Future<User> register(String name, String email, String password) async {
    final data = await _api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return _saveSession(data);
  }

  /// Si hay un token guardado, valida que siga vigente y devuelve al usuario.
  Future<User?> restoreSession() async {
    final saved = await _storage.read(key: _tokenKey);
    if (saved == null) return null;
    _api.token = saved;
    try {
      final data = await _api.get('/auth/me');
      return User.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    _api.token = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<User> _saveSession(dynamic data) async {
    final token = data['access_token'] as String;
    _api.token = token;
    await _storage.write(key: _tokenKey, value: token);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }
}
