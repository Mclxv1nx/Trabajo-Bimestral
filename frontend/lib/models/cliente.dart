class Cliente {
  final int? id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String? email;
  final String? telefono;
  final String? direccion;
  final bool activo;

  Cliente({
    this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    this.email,
    this.telefono,
    this.direccion,
    this.activo = true,
  });

  String get nombreCompleto => '$nombres $apellidos';

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'] as int?,
        cedula: json['cedula'] as String,
        nombres: json['nombres'] as String,
        apellidos: json['apellidos'] as String,
        email: json['email'] as String?,
        telefono: json['telefono'] as String?,
        direccion: json['direccion'] as String?,
        activo: json['activo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
        'email': email,
        'telefono': telefono,
        'direccion': direccion,
        'activo': activo,
      };
}
