import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cliente.dart';
import '../models/tipo_vehiculo.dart';
import '../models/vehiculo.dart';

/// Excepción con el mensaje devuelto por el API.
class ApiException implements Exception {
  final int statusCode;
  final String mensaje;
  ApiException(this.statusCode, this.mensaje);

  @override
  String toString() => mensaje;
}

class ApiService {
  static const _base = ApiConfig.baseUrl;
  static const _headers = {'Content-Type': 'application/json'};

  static Future<dynamic> _procesar(http.Response res) async {
    final body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    String mensaje = 'Error ${res.statusCode}';
    if (body is Map<String, dynamic>) {
      if (body['errores'] is List && (body['errores'] as List).isNotEmpty) {
        mensaje = (body['errores'] as List)
            .map((e) => e['mensaje'])
            .whereType<String>()
            .join('\n');
      } else if (body['mensaje'] is String) {
        mensaje = body['mensaje'] as String;
      }
    }
    throw ApiException(res.statusCode, mensaje);
  }

  static Future<dynamic> _get(String ruta) async =>
      _procesar(await http.get(Uri.parse('$_base$ruta')).timeout(ApiConfig.timeout));

  static Future<dynamic> _post(String ruta, Map<String, dynamic> data) async =>
      _procesar(await http
          .post(Uri.parse('$_base$ruta'), headers: _headers, body: jsonEncode(data))
          .timeout(ApiConfig.timeout));

  static Future<dynamic> _put(String ruta, Map<String, dynamic> data) async =>
      _procesar(await http
          .put(Uri.parse('$_base$ruta'), headers: _headers, body: jsonEncode(data))
          .timeout(ApiConfig.timeout));

  static Future<dynamic> _delete(String ruta) async =>
      _procesar(await http.delete(Uri.parse('$_base$ruta')).timeout(ApiConfig.timeout));

  // ---------- Tipos de vehículo ----------
  static Future<List<TipoVehiculo>> getTipos() async {
    final data = await _get('/api/tipos-vehiculo') as List;
    return data.map((e) => TipoVehiculo.fromJson(e)).toList();
  }

  static Future<TipoVehiculo> crearTipo(TipoVehiculo t) async =>
      TipoVehiculo.fromJson(await _post('/api/tipos-vehiculo', t.toJson()));

  static Future<TipoVehiculo> actualizarTipo(int id, TipoVehiculo t) async =>
      TipoVehiculo.fromJson(await _put('/api/tipos-vehiculo/$id', t.toJson()));

  static Future<void> eliminarTipo(int id) async =>
      _delete('/api/tipos-vehiculo/$id');

  // ---------- Clientes ----------
  static Future<List<Cliente>> getClientes() async {
    final data = await _get('/api/clientes') as List;
    return data.map((e) => Cliente.fromJson(e)).toList();
  }

  static Future<Cliente> crearCliente(Cliente c) async =>
      Cliente.fromJson(await _post('/api/clientes', c.toJson()));

  static Future<Cliente> actualizarCliente(int id, Cliente c) async =>
      Cliente.fromJson(await _put('/api/clientes/$id', c.toJson()));

  static Future<void> eliminarCliente(int id) async =>
      _delete('/api/clientes/$id');

  // ---------- Vehículos ----------
  static Future<List<Vehiculo>> getVehiculos({
    int? tipoId,
    String? estado,
    String? buscar,
  }) async {
    final params = <String, String>{};
    if (tipoId != null) params['tipo_id'] = '$tipoId';
    if (estado != null && estado.isNotEmpty) params['estado'] = estado;
    if (buscar != null && buscar.trim().isNotEmpty) params['buscar'] = buscar.trim();
    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final data = await _get('/api/vehiculos$query') as List;
    return data.map((e) => Vehiculo.fromJson(e)).toList();
  }

  static Future<Vehiculo> crearVehiculo(Vehiculo v) async =>
      Vehiculo.fromJson(await _post('/api/vehiculos', v.toJson()));

  static Future<Vehiculo> actualizarVehiculo(int id, Vehiculo v) async =>
      Vehiculo.fromJson(await _put('/api/vehiculos/$id', v.toJson()));

  static Future<void> eliminarVehiculo(int id) async =>
      _delete('/api/vehiculos/$id');
}
