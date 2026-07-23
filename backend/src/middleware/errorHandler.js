/** Manejador central de errores: traduce errores de PostgreSQL a respuestas claras */
function errorHandler(err, req, res, next) {
  console.error(`[ERROR] ${req.method} ${req.originalUrl}:`, err.message);

  // Violación de unicidad (placa, cédula, nombre duplicado...)
  if (err.code === '23505') {
    return res.status(409).json({
      ok: false,
      mensaje: 'Ya existe un registro con ese valor único (duplicado)',
      detalle: err.detail,
    });
  }
  // Violación de llave foránea o restricción RESTRICT
  if (err.code === '23503' || err.code === '23001') {
    return res.status(409).json({
      ok: false,
      mensaje: 'Operación no permitida: el registro está relacionado con otros datos',
      detalle: err.detail,
    });
  }
  // Violación de CHECK constraint
  if (err.code === '23514') {
    return res.status(400).json({
      ok: false,
      mensaje: 'Los datos no cumplen las restricciones de la base de datos',
      detalle: err.detail || err.message,
    });
  }
  // Sin conexión a la BD
  if (err.code === 'ECONNREFUSED' || err.code === '57P03') {
    return res.status(503).json({
      ok: false,
      mensaje: 'No se pudo conectar a la base de datos PostgreSQL',
    });
  }

  res.status(500).json({ ok: false, mensaje: 'Error interno del servidor' });
}

module.exports = errorHandler;
