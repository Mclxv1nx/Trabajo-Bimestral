import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../services/api_service.dart';
import '../utils/toast.dart';
import '../widgets/comunes.dart';

/// CRUD de clientes.
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late Future<List<Cliente>> _futuro;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _futuro = ApiService.getClientes();
  }

  void _refrescar() => setState(() => _futuro = ApiService.getClientes());

  Future<void> _abrirFormulario({Cliente? cliente}) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioCliente(cliente: cliente),
    );
    if (guardado == true) _refrescar();
  }

  Future<void> _eliminar(Cliente c) async {
    final confirmado = await confirmarEliminacion(
      context,
      titulo: 'Eliminar cliente',
      mensaje:
          '¿Seguro que deseas eliminar a ${c.nombreCompleto}? Sus vehículos quedarán sin propietario.',
    );
    if (!confirmado || !mounted) return;
    try {
      await ApiService.eliminarCliente(c.id!);
      if (!mounted) return;
      Toast.exito(context, 'Cliente eliminado',
          '${c.nombreCompleto} se eliminó correctamente');
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
        title: const Text('Clientes'),
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
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo cliente'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o cédula...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Cliente>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return EstadoError(
                      mensaje: '${snap.error}', onReintentar: _refrescar);
                }
                var clientes = snap.data!;
                if (_busqueda.isNotEmpty) {
                  clientes = clientes
                      .where((c) =>
                          c.nombreCompleto.toLowerCase().contains(_busqueda) ||
                          c.cedula.contains(_busqueda))
                      .toList();
                }
                if (clientes.isEmpty) {
                  return EstadoVacio(
                    icono: Icons.people_outline,
                    titulo: _busqueda.isEmpty
                        ? 'No hay clientes registrados'
                        : 'Sin resultados para "$_busqueda"',
                    subtitulo: _busqueda.isEmpty
                        ? 'Registra tu primer cliente'
                        : 'Prueba con otro término de búsqueda',
                    textoAccion: _busqueda.isEmpty ? 'Nuevo cliente' : null,
                    onAccion:
                        _busqueda.isEmpty ? () => _abrirFormulario() : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refrescar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: clientes.length,
                    itemBuilder: (context, i) {
                      final c = clientes[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.tertiaryContainer,
                            child: Text(
                              c.nombres.isNotEmpty ? c.nombres[0] : '?',
                              style: TextStyle(
                                  color: cs.onTertiaryContainer,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c.nombreCompleto,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CI: ${c.cedula}'),
                              if (c.email?.isNotEmpty == true) Text(c.email!),
                              if (c.telefono?.isNotEmpty == true)
                                Text('Tel: ${c.telefono}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _abrirFormulario(cliente: c),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon:
                                    Icon(Icons.delete_outline, color: cs.error),
                                onPressed: () => _eliminar(c),
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

class _FormularioCliente extends StatefulWidget {
  final Cliente? cliente;
  const _FormularioCliente({this.cliente});

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cedula;
  late final TextEditingController _nombres;
  late final TextEditingController _apellidos;
  late final TextEditingController _email;
  late final TextEditingController _telefono;
  late final TextEditingController _direccion;
  bool _guardando = false;

  bool get esEdicion => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _cedula = TextEditingController(text: c?.cedula ?? '');
    _nombres = TextEditingController(text: c?.nombres ?? '');
    _apellidos = TextEditingController(text: c?.apellidos ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _telefono = TextEditingController(text: c?.telefono ?? '');
    _direccion = TextEditingController(text: c?.direccion ?? '');
  }

  @override
  void dispose() {
    for (final ctrl in [_cedula, _nombres, _apellidos, _email, _telefono, _direccion]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final cliente = Cliente(
      cedula: _cedula.text.trim(),
      nombres: _nombres.text.trim(),
      apellidos: _apellidos.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      telefono: _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
      direccion: _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
    );
    try {
      if (esEdicion) {
        await ApiService.actualizarCliente(widget.cliente!.id!, cliente);
        if (!mounted) return;
        Toast.exito(context, 'Cliente actualizado',
            '${cliente.nombreCompleto} se guardó correctamente');
      } else {
        await ApiService.crearCliente(cliente);
        if (!mounted) return;
        Toast.exito(context, 'Cliente creado',
            '${cliente.nombreCompleto} se registró correctamente');
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
      title: Text(esEdicion ? 'Editar cliente' : 'Nuevo cliente'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _cedula,
                  autofocus: !esEdicion,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cédula *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'La cédula es obligatoria';
                    if (t.length < 10) return 'Mínimo 10 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombres,
                  decoration: const InputDecoration(
                    labelText: 'Nombres *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Los nombres son obligatorios'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apellidos,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Los apellidos son obligatorios'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    return regex.hasMatch(t) ? null : 'Email inválido';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _direccion,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.home_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
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
