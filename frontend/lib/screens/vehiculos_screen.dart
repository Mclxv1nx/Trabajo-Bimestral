import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/vehiculo.dart';
import '../services/api_service.dart';
import '../utils/toast.dart';
import '../widgets/comunes.dart';
import 'vehiculo_form_screen.dart';

/// Listado de vehículos con búsqueda, filtros y acciones CRUD.
class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  late Future<List<Vehiculo>> _futuro;
  final _busquedaCtrl = TextEditingController();
  String? _estadoFiltro;
  final _moneda = NumberFormat.currency(locale: 'es_EC', symbol: r'$');

  @override
  void initState() {
    super.initState();
    _futuro = ApiService.getVehiculos();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _refrescar() => setState(() {
        _futuro = ApiService.getVehiculos(
          estado: _estadoFiltro,
          buscar: _busquedaCtrl.text,
        );
      });

  Future<void> _abrirFormulario({Vehiculo? vehiculo}) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => VehiculoFormScreen(vehiculo: vehiculo)),
    );
    if (guardado == true) _refrescar();
  }

  Future<void> _eliminar(Vehiculo v) async {
    final confirmado = await confirmarEliminacion(
      context,
      titulo: 'Eliminar vehículo',
      mensaje:
          '¿Seguro que deseas eliminar el ${v.marca} ${v.modelo} con placa ${v.placa}?',
    );
    if (!confirmado || !mounted) return;
    try {
      await ApiService.eliminarVehiculo(v.id!);
      if (!mounted) return;
      Toast.exito(context, 'Vehículo eliminado',
          'Placa ${v.placa} eliminada correctamente');
      _refrescar();
    } catch (e) {
      if (!mounted) return;
      Toast.error(context, 'No se pudo eliminar', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículos'),
        centerTitle: false,
        actions: [
          IconButton(
              tooltip: 'Actualizar',
              onPressed: _refrescar,
              icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo vehículo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por placa, marca o modelo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busquedaCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaCtrl.clear();
                          _refrescar();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _refrescar(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _estadoFiltro == null,
                  onSelected: (_) {
                    _estadoFiltro = null;
                    _refrescar();
                  },
                ),
                const SizedBox(width: 8),
                ...Vehiculo.estados.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(e),
                      selected: _estadoFiltro == e,
                      onSelected: (_) {
                        _estadoFiltro = _estadoFiltro == e ? null : e;
                        _refrescar();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Vehiculo>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return EstadoError(
                      mensaje: '${snap.error}', onReintentar: _refrescar);
                }
                final vehiculos = snap.data!;
                if (vehiculos.isEmpty) {
                  return EstadoVacio(
                    icono: Icons.directions_car_outlined,
                    titulo: 'No se encontraron vehículos',
                    subtitulo:
                        'Ajusta los filtros o registra un nuevo vehículo',
                    textoAccion: 'Nuevo vehículo',
                    onAccion: () => _abrirFormulario(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refrescar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: vehiculos.length,
                    itemBuilder: (context, i) {
                      final v = vehiculos[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: cs.primaryContainer,
                                    child: Icon(Icons.directions_car,
                                        color: cs.onPrimaryContainer),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${v.marca} ${v.modelo} (${v.anio})',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15),
                                        ),
                                        Text(
                                          'Placa ${v.placa} · ${v.tipoNombre ?? "Sin tipo"}',
                                          style: TextStyle(
                                              color: cs.outline, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  EstadoChip(estado: v.estado),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 16,
                                runSpacing: 4,
                                children: [
                                  if (v.precio != null)
                                    _Dato(
                                        icono: Icons.attach_money,
                                        texto: _moneda.format(v.precio)),
                                  _Dato(
                                      icono: Icons.speed,
                                      texto:
                                          '${NumberFormat.decimalPattern('es').format(v.kilometraje)} km'),
                                  if (v.color?.isNotEmpty == true)
                                    _Dato(
                                        icono: Icons.palette_outlined,
                                        texto: v.color!),
                                  if (v.clienteNombre != null)
                                    _Dato(
                                        icono: Icons.person_outline,
                                        texto: v.clienteNombre!),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _abrirFormulario(vehiculo: v),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    label: const Text('Editar'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: cs.error),
                                    onPressed: () => _eliminar(v),
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    label: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Dato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: cs.outline),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
