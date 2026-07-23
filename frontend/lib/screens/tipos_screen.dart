import 'package:flutter/material.dart';

import '../models/tipo_vehiculo.dart';
import '../services/api_service.dart';
import '../utils/toast.dart';
import '../widgets/comunes.dart';

/// CRUD de tipos de vehículo.
class TiposScreen extends StatefulWidget {
  const TiposScreen({super.key});

  @override
  State<TiposScreen> createState() => _TiposScreenState();
}

class _TiposScreenState extends State<TiposScreen> {
  late Future<List<TipoVehiculo>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ApiService.getTipos();
  }

  void _refrescar() => setState(() => _futuro = ApiService.getTipos());

  Future<void> _abrirFormulario({TipoVehiculo? tipo}) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioTipo(tipo: tipo),
    );
    if (guardado == true) _refrescar();
  }

  Future<void> _eliminar(TipoVehiculo tipo) async {
    final confirmado = await confirmarEliminacion(
      context,
      titulo: 'Eliminar tipo',
      mensaje:
          '¿Seguro que deseas eliminar "${tipo.nombre}"? Esta acción no se puede deshacer.',
    );
    if (!confirmado || !mounted) return;
    try {
      await ApiService.eliminarTipo(tipo.id!);
      if (!mounted) return;
      Toast.exito(context, 'Tipo eliminado', '"${tipo.nombre}" se eliminó correctamente');
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
        title: const Text('Tipos de Vehículo'),
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
        label: const Text('Nuevo tipo'),
      ),
      body: FutureBuilder<List<TipoVehiculo>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoError(mensaje: '${snap.error}', onReintentar: _refrescar);
          }
          final tipos = snap.data!;
          if (tipos.isEmpty) {
            return EstadoVacio(
              icono: Icons.category_outlined,
              titulo: 'No hay tipos de vehículo',
              subtitulo: 'Crea el primero para poder registrar vehículos',
              textoAccion: 'Nuevo tipo',
              onAccion: () => _abrirFormulario(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refrescar(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: tipos.length,
              itemBuilder: (context, i) {
                final t = tipos[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          t.activo ? cs.primaryContainer : cs.surfaceContainerHighest,
                      child: Icon(Icons.category,
                          color: t.activo ? cs.onPrimaryContainer : cs.outline),
                    ),
                    title: Text(t.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      t.descripcion?.isNotEmpty == true
                          ? t.descripcion!
                          : 'Sin descripción',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!t.activo)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: const Text('Inactivo'),
                              labelStyle: const TextStyle(fontSize: 11),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: cs.surfaceContainerHighest,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _abrirFormulario(tipo: t),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          icon: Icon(Icons.delete_outline, color: cs.error),
                          onPressed: () => _eliminar(t),
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
    );
  }
}

class _FormularioTipo extends StatefulWidget {
  final TipoVehiculo? tipo;
  const _FormularioTipo({this.tipo});

  @override
  State<_FormularioTipo> createState() => _FormularioTipoState();
}

class _FormularioTipoState extends State<_FormularioTipo> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late bool _activo;
  bool _guardando = false;

  bool get esEdicion => widget.tipo != null;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.tipo?.nombre ?? '');
    _descripcion = TextEditingController(text: widget.tipo?.descripcion ?? '');
    _activo = widget.tipo?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final tipo = TipoVehiculo(
      nombre: _nombre.text.trim(),
      descripcion:
          _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      activo: _activo,
    );
    try {
      if (esEdicion) {
        await ApiService.actualizarTipo(widget.tipo!.id!, tipo);
        if (!mounted) return;
        Toast.exito(context, 'Tipo actualizado',
            '"${tipo.nombre}" se guardó correctamente');
      } else {
        await ApiService.crearTipo(tipo);
        if (!mounted) return;
        Toast.exito(context, 'Tipo creado', '"${tipo.nombre}" se registró correctamente');
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
    return AlertDialog(
      title: Text(esEdicion ? 'Editar tipo' : 'Nuevo tipo de vehículo'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombre,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcion,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Activo'),
                subtitle: const Text('Disponible para nuevos vehículos'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(esEdicion ? 'Guardar cambios' : 'Crear'),
        ),
      ],
    );
  }
}
