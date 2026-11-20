/// Dirección de la API.
///
/// - Emulador de Android: http://10.0.2.2:8000  (10.0.2.2 apunta a tu PC)
/// - Simulador de iOS / Flutter web: http://localhost:8000
/// - Celular físico: usa la IP de tu PC en la red, ej. http://192.168.1.50:8000
///
/// También se puede cambiar al ejecutar:
///   flutter run --dart-define=API_URL=http://192.168.1.50:8000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
