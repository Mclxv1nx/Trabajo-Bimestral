import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Toasts estilo "toastify": éxito, error e información.
class Toast {
  static void _show(
    BuildContext context,
    String titulo,
    String? detalle,
    ToastificationType tipo,
  ) {
    toastification.show(
      context: context,
      type: tipo,
      style: ToastificationStyle.flatColored,
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      description: detalle == null ? null : Text(detalle),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      borderRadius: BorderRadius.circular(12),
    );
  }

  static void exito(BuildContext context, String titulo, [String? detalle]) =>
      _show(context, titulo, detalle, ToastificationType.success);

  static void error(BuildContext context, String titulo, [String? detalle]) =>
      _show(context, titulo, detalle, ToastificationType.error);

  static void info(BuildContext context, String titulo, [String? detalle]) =>
      _show(context, titulo, detalle, ToastificationType.info);

  static void advertencia(BuildContext context, String titulo, [String? detalle]) =>
      _show(context, titulo, detalle, ToastificationType.warning);
}
