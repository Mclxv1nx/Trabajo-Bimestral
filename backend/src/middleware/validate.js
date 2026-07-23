const { validationResult } = require('express-validator');

/** Middleware que devuelve 400 con la lista de errores de validación */
function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      ok: false,
      mensaje: 'Datos inválidos',
      errores: errors.array().map((e) => ({ campo: e.path, mensaje: e.msg })),
    });
  }
  next();
}

module.exports = validate;
