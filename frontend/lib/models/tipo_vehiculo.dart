class TipoVehiculo {
  final int? id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  TipoVehiculo({
    this.id,
    required this.nombre,
    this.descripcion,
    this.activo = true,
  });

  factory TipoVehiculo.fromJson(Map<String, dynamic> json) => TipoVehiculo(
        id: json['id'] as int?,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        activo: json['activo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'activo': activo,
      };
}
