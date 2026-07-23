class Vehiculo {
  final int? id;
  final String placa;
  final String marca;
  final String modelo;
  final int anio;
  final String? color;
  final double? precio;
  final int kilometraje;
  final String estado;
  final int tipoId;
  final int? clienteId;
  final String? tipoNombre;
  final String? clienteNombre;

  static const List<String> estados = [
    'DISPONIBLE',
    'VENDIDO',
    'RESERVADO',
    'MANTENIMIENTO',
  ];

  Vehiculo({
    this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.anio,
    this.color,
    this.precio,
    this.kilometraje = 0,
    this.estado = 'DISPONIBLE',
    required this.tipoId,
    this.clienteId,
    this.tipoNombre,
    this.clienteNombre,
  });

  static double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
        id: json['id'] as int?,
        placa: json['placa'] as String,
        marca: json['marca'] as String,
        modelo: json['modelo'] as String,
        anio: json['anio'] as int,
        color: json['color'] as String?,
        precio: _toDouble(json['precio']),
        kilometraje: json['kilometraje'] as int? ?? 0,
        estado: json['estado'] as String? ?? 'DISPONIBLE',
        tipoId: json['tipo_id'] as int,
        clienteId: json['cliente_id'] as int?,
        tipoNombre: json['tipo_nombre'] as String?,
        clienteNombre: json['cliente_nombre'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'placa': placa,
        'marca': marca,
        'modelo': modelo,
        'anio': anio,
        'color': color,
        'precio': precio,
        'kilometraje': kilometraje,
        'estado': estado,
        'tipo_id': tipoId,
        'cliente_id': clienteId,
      };
}
