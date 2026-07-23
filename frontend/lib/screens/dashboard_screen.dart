import 'package:flutter/material.dart';

import '../models/vehiculo.dart';
import '../services/api_service.dart';
import '../widgets/comunes.dart';

/// Panel inicial con resumen de datos del sistema.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_Resumen> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_Resumen> _cargar() async {
    final resultados = await Future.wait([
      ApiService.getVehiculos(),
      ApiService.getTipos(),
      ApiService.getClientes(),
    ]);
    return _Resumen(
      vehiculos: resultados[0] as List<Vehiculo>,
      totalTipos: (resultados[1] as List).length,
      totalClientes: (resultados[2] as List).length,
    );
  }

  void _refrescar() => setState(() => _futuro = _cargar());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Vehículos'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_Resumen>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoError(
              mensaje:
                  '${snap.error}\n\nVerifica que el API esté corriendo en http://localhost:3000',
              onReintentar: _refrescar,
            );
          }
          final r = snap.data!;
          final disponibles =
              r.vehiculos.where((v) => v.estado == 'DISPONIBLE').length;
          final vendidos = r.vehiculos.where((v) => v.estado == 'VENDIDO').length;

          return RefreshIndicator(
            onRefresh: () async => _refrescar(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Resumen general',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _TarjetaMetrica(
                      icono: Icons.directions_car,
                      valor: '${r.vehiculos.length}',
                      etiqueta: 'Vehículos',
                      color: cs.primary,
                    ),
                    _TarjetaMetrica(
                      icono: Icons.check_circle,
                      valor: '$disponibles',
                      etiqueta: 'Disponibles',
                      color: Colors.green,
                    ),
                    _TarjetaMetrica(
                      icono: Icons.sell,
                      valor: '$vendidos',
                      etiqueta: 'Vendidos',
                      color: Colors.blueGrey,
                    ),
                    _TarjetaMetrica(
                      icono: Icons.category,
                      valor: '${r.totalTipos}',
                      etiqueta: 'Tipos',
                      color: Colors.deepPurple,
                    ),
                    _TarjetaMetrica(
                      icono: Icons.people,
                      valor: '${r.totalClientes}',
                      etiqueta: 'Clientes',
                      color: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Últimos vehículos',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (r.vehiculos.isEmpty)
                  const EstadoVacio(
                    icono: Icons.directions_car_outlined,
                    titulo: 'Aún no hay vehículos registrados',
                    subtitulo: 'Usa la pestaña Vehículos para agregar el primero',
                  )
                else
                  ...r.vehiculos.reversed.take(5).map(
                        (v) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Icon(Icons.directions_car,
                                  color: cs.onPrimaryContainer),
                            ),
                            title: Text('${v.marca} ${v.modelo} (${v.anio})'),
                            subtitle: Text(
                                'Placa ${v.placa} · ${v.tipoNombre ?? "Sin tipo"}'),
                            trailing: EstadoChip(estado: v.estado),
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Resumen {
  final List<Vehiculo> vehiculos;
  final int totalTipos;
  final int totalClientes;
  _Resumen({
    required this.vehiculos,
    required this.totalTipos,
    required this.totalClientes,
  });
}

class _TarjetaMetrica extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;

  const _TarjetaMetrica({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(height: 12),
          Text(valor,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
