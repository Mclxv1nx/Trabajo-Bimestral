/// Configuración del API.
///
/// - Flutter Web / Windows / escritorio: http://localhost:3000
/// - Emulador Android: cambiar a http://10.0.2.2:3000
/// - Dispositivo físico: usar la IP de tu PC, ej. http://192.168.1.10:3000
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';
  static const Duration timeout = Duration(seconds: 10);
}
