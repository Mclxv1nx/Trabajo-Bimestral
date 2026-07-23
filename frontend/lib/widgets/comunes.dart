import 'package:flutter/material.dart';

/// Estado vacío con icono, mensaje y acción opcional.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final String? textoAccion;
  final VoidCallback? onAccion;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.textoAccion,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 72, color: cs.outline),
            const SizedBox(height: 16),
            Text(titulo,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(subtitulo!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.outline),
                  textAlign: TextAlign.center),
            ],
            if (textoAccion != null && onAccion != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAccion,
                icon: const Icon(Icons.add),
                label: Text(textoAccion!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error con botón de reintento.
class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const EstadoError({super.key, required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 72, color: cs.error),
            const SizedBox(height: 16),
            Text('No se pudo cargar la información',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(mensaje,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.outline),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de confirmación para eliminar. Devuelve true si el usuario confirma.
Future<bool> confirmarEliminacion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.warning_amber_rounded,
          color: Theme.of(ctx).colorScheme.error, size: 36),
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return resultado ?? false;
}

/// Chip de estado del vehículo con color semántico.
class EstadoChip extends StatelessWidget {
  final String estado;
  const EstadoChip({super.key, required this.estado});

  Color _color() {
    switch (estado) {
      case 'DISPONIBLE':
        return Colors.green;
      case 'VENDIDO':
        return Colors.blueGrey;
      case 'RESERVADO':
        return Colors.orange;
      case 'MANTENIMIENTO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Text(
        estado,
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
