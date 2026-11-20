import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

/// Estado global de la sesión. La pantalla raíz cambia según este estado.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service, ApiClient api) {
    // Si la API dice que el token venció, cerramos la sesión automáticamente.
    api.onUnauthorized = () {
      if (status == AuthStatus.authenticated) {
        logout();
        sessionExpired = true;
        notifyListeners();
      }
    };
  }

  final AuthService _service;

  AuthStatus status = AuthStatus.checking;
  User? user;
  bool sessionExpired = false;

  Future<void> tryAutoLogin() async {
    user = await _service.restoreSession();
    status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    user = await _service.login(email.trim(), password);
    sessionExpired = false;
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    user = await _service.register(name.trim(), email.trim(), password);
    sessionExpired = false;
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
