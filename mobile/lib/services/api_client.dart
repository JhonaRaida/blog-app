import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Error legible para mostrar al usuario.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Cliente HTTP único de la app: agrega el token a cada petición y
/// traduce los errores de la API a mensajes en español.
class ApiClient {
  final http.Client _http = http.Client();

  /// Token JWT de la sesión actual (null si no hay sesión).
  String? token;

  /// Se llama cuando la API responde 401 con una sesión activa (token vencido).
  void Function()? onUnauthorized;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) => _send(() => _http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send(() => _http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send(() => _http.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> delete(String path) => _send(() => _http.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder');
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    if (res.statusCode == 401 && token != null) {
      onUnauthorized?.call();
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    throw ApiException(_errorMessage(res), res.statusCode);
  }

  /// Extrae el mensaje del campo "detail" que devuelve FastAPI.
  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final msg = (detail.first['msg'] ?? '').toString();
        return msg.replaceFirst('Value error, ', '');
      }
    } catch (_) {}
    return 'Error del servidor (${res.statusCode})';
  }
}
