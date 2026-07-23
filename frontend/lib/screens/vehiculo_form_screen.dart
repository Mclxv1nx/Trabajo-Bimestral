import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/tipo_vehiculo.dart';
import '../models/vehiculo.dart';
import '../services/api_service.dart';
import '../utils/toast.dart';

/// Formulario de creación/edición de vehículo (pantalla completa).
class VehiculoFormScreen extends StatefulWidget {
  final Vehiculo? vehiculo;
  const VehiculoFormScreen({super.key, this.vehiculo});

  @override
  State<VehiculoFormScreen> createState() => _VehiculoFormScreenState();
}

class _VehiculoFormScreenState extends State<VehiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _placa;
  late final TextEditingController _marca;
  late final TextEditingController _modelo;
  late final TextEditingController _anio;
  late final TextEditingController _color;
  late final TextEditingController _precio;
  late final TextEditingController _kilometraje;

  String _estado = 'DISPONIBLE';
  int? _tipoId;
  int? _clienteId;

  List<TipoVehiculo> _tipos = [];
  List<Cliente> _clientes = [];
  bool _cargandoCatalogos = true;
  bool _guardando = false;
  String? _errorCatalogos;

  bool get esEdicion => widget.vehiculo != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehiculo;
    _placa = TextEditingController(text: v?.placa ?? '');
    _marca = TextEditingController(text: v?.marca ?? '');
    _modelo = TextEditingController(text: v?.modelo ?? '');
    _anio = TextEditingController(text: v?.anio.toString() ?? '');
    _color = TextEditingController(text: v?.color ?? '');
    _precio = TextEditingController(text: v?.precio?.toStringAsFixed(2) ?? '');
    _kilometraje = TextEditingController(text: v?.kilometraje.toString() ?? '0');
    _estado = v?.estado ?? 'DISPONIBLE';
    _tipoId = v?.tipoId;
    _clienteId = v?.clienteId;
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCatalogos = null;
    });
    try {
      final resultados = await Future.wait([
        ApiService.getTipos(),
        ApiService.getClientes(),
      ]);
      setState(() {
        _tipos = (resultados[0] as List<TipoVehiculo>)
            .where((t) => t.activo || t.id == _tipoId)
            .toList();
        _clientes = resultados[1] as List<Cliente>;
        _cargandoCatalogos = false;
      });
    } catch (e) {
      setState(() {
        _cargandoCatalogos = false;
        _errorCatalogos = e.toString();
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_placa, _marca, _modelo, _anio, _color, _precio, _kilometraje]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      Toast.advertencia(context, 'Revisa el formulario',
          'Hay campos con errores o incompletos');
      return;
    }
    setState(() => _guardando = true);
    final vehiculo = Vehiculo(
      placa: _placa.text.trim().toUpperCase(),
      marca: _marca.text.trim(),
      modelo: _modelo.text.trim(),
      anio: int.parse(_anio.text.trim()),
      color: _color.text.trim().isEmpty ? null : _color.text.trim(),
      precio: _precio.text.trim().isEmpty
          ? null
          : double.parse(_precio.text.trim().replaceAll(',', '.')),
      kilometraje: int.tryParse(_kilometraje.text.trim()) ?? 0,
      estado: _estado,
      tipoId: _tipoId!,
      clienteId: _clienteId,
    );
    try {
      if (esEdicion) {
        await ApiService.actualizarVehiculo(widget.vehiculo!.id!, vehiculo);
        if (!mounted) return;
        Toast.exito(context, 'Vehículo actualizado',
            'Placa ${vehiculo.placa} guardada correctamente');
      } else {
        await ApiService.crearVehiculo(vehiculo);
        if (!mounted) return;
        Toast.exito(context, 'Vehículo registrado',
            'Placa ${vehiculo.placa} creada correctamente');
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      Toast.error(context, 'No se pudo guardar', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion
            ? 'Editar vehículo ${widget.vehiculo!.placa}'
            : 'Nuevo vehículo'),
      ),
      body: _cargandoCatalogos
          ? const Center(child: CircularProgressIndicator())
          : _errorCatalogos != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error cargando catálogos: $_errorCatalogos'),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: _cargarCatalogos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Datos del vehículo',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _placa,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: const InputDecoration(
                                        labelText: 'Placa *',
                                        prefixIcon:
                                            Icon(Icons.pin_outlined),
                                        hintText: 'ABC-1234',
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'La placa es obligatoria'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _anio,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Año *',
                                        prefixIcon:
                                            Icon(Icons.calendar_today_outlined),
                                      ),
                                      validator: (v) {
                                        final n = int.tryParse(v?.trim() ?? '');
                                        if (n == null) return 'Año inválido';
                                        if (n < 1900 || n > 2100) {
                                          return 'Entre 1900 y 2100';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _marca,
                                      decoration: const InputDecoration(
                                        labelText: 'Marca *',
                                        prefixIcon:
                                            Icon(Icons.factory_outlined),
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'La marca es obligatoria'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _modelo,
                                      decoration: const InputDecoration(
                                        labelText: 'Modelo *',
                                        prefixIcon:
                                            Icon(Icons.drive_eta_outlined),
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'El modelo es obligatorio'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                value: _tipoId,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de vehículo *',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                items: _tipos
                                    .map((t) => DropdownMenuItem(
                                        value: t.id, child: Text(t.nombre)))
                                    .toList(),
                                onChanged: (v) => setState(() => _tipoId = v),
                                validator: (v) =>
                                    v == null ? 'Selecciona un tipo' : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Detalles y estado',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _color,
                                      decoration: const InputDecoration(
                                        labelText: 'Color',
                                        prefixIcon:
                                            Icon(Icons.palette_outlined),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _kilometraje,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Kilometraje',
                                        prefixIcon: Icon(Icons.speed),
                                        suffixText: 'km',
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return null;
                                        }
                                        final n = int.tryParse(v.trim());
                                        if (n == null || n < 0) {
                                          return 'Valor inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _precio,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Precio',
                                  prefixIcon: Icon(Icons.attach_money),
                                  hintText: '24500.00',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return null;
                                  }
                                  final n = double.tryParse(
                                      v.trim().replaceAll(',', '.'));
                                  if (n == null || n < 0) {
                                    return 'Precio inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _estado,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  prefixIcon: Icon(Icons.flag_outlined),
                                ),
                                items: Vehiculo.estados
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _estado = v ?? 'DISPONIBLE'),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int?>(
                                value: _clienteId,
                                decoration: const InputDecoration(
                                  labelText: 'Propietario (opcional)',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Sin propietario')),
                                  ..._clientes.map((c) => DropdownMenuItem<int?>(
                                      value: c.id,
                                      child: Text(
                                          '${c.nombreCompleto} (${c.cedula})'))),
                                ],
                                onChanged: (v) =>
                                    setState(() => _clienteId = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _guardando
                                  ? null
                                  : () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _guardando ? null : _guardar,
                              icon: _guardando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.save),
                              label: Text(esEdicion
                                  ? 'Guardar cambios'
                                  : 'Registrar vehículo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
