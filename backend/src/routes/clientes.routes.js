const { Router } = require('express');
const { body, param } = require('express-validator');
const pool = require('../db/pool');
const validate = require('../middleware/validate');

const router = Router();

const reglas = [
  body('cedula').trim().notEmpty().withMessage('La cédula es obligatoria')
    .isLength({ min: 10, max: 20 }).withMessage('La cédula debe tener entre 10 y 20 caracteres'),
  body('nombres').trim().notEmpty().withMessage('Los nombres son obligatorios'),
  body('apellidos').trim().notEmpty().withMessage('Los apellidos son obligatorios'),
  body('email').optional({ nullable: true, checkFalsy: true }).isEmail().withMessage('Email inválido'),
  body('telefono').optional({ nullable: true, checkFalsy: true }).isLength({ max: 20 }),
  body('direccion').optional({ nullable: true }).isString(),
  body('activo').optional().isBoolean(),
];
const idValido = [param('id').isInt({ min: 1 }).withMessage('El id debe ser un entero positivo')];

/**
 * @openapi
 * /api/clientes:
 *   get:
 *     tags: [Clientes]
 *     summary: Listar todos los clientes
 *     responses:
 *       200:
 *         description: Lista de clientes
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { $ref: '#/components/schemas/Cliente' }
 *   post:
 *     tags: [Clientes]
 *     summary: Crear un cliente
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/ClienteInput' }
 *     responses:
 *       201:
 *         description: Cliente creado
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Cliente' }
 *       400: { $ref: '#/components/responses/BadRequest' }
 *       409: { $ref: '#/components/responses/Conflict' }
 */
router.get('/', async (req, res, next) => {
  try {
    const { rows } = await pool.query('SELECT * FROM clientes ORDER BY id');
    res.json(rows);
  } catch (err) { next(err); }
});

router.post('/', reglas, validate, async (req, res, next) => {
  try {
    const { cedula, nombres, apellidos, email = null, telefono = null, direccion = null, activo = true } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO clientes (cedula, nombres, apellidos, email, telefono, direccion, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [cedula, nombres, apellidos, email || null, telefono, direccion, activo]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
});

/**
 * @openapi
 * /api/clientes/{id}:
 *   get:
 *     tags: [Clientes]
 *     summary: Obtener un cliente por id
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Cliente
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Cliente' }
 *       404: { $ref: '#/components/responses/NotFound' }
 *   put:
 *     tags: [Clientes]
 *     summary: Actualizar un cliente
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/ClienteInput' }
 *     responses:
 *       200:
 *         description: Cliente actualizado
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Cliente' }
 *       400: { $ref: '#/components/responses/BadRequest' }
 *       404: { $ref: '#/components/responses/NotFound' }
 *       409: { $ref: '#/components/responses/Conflict' }
 *   delete:
 *     tags: [Clientes]
 *     summary: Eliminar un cliente
 *     description: Los vehículos asociados quedan sin propietario (cliente_id = NULL).
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200: { description: Cliente eliminado }
 *       404: { $ref: '#/components/responses/NotFound' }
 */
router.get('/:id', idValido, validate, async (req, res, next) => {
  try {
    const { rows } = await pool.query('SELECT * FROM clientes WHERE id = $1', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ ok: false, mensaje: 'Cliente no encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

router.put('/:id', [...idValido, ...reglas], validate, async (req, res, next) => {
  try {
    const { cedula, nombres, apellidos, email = null, telefono = null, direccion = null, activo = true } = req.body;
    const { rows } = await pool.query(
      `UPDATE clientes SET cedula = $1, nombres = $2, apellidos = $3, email = $4,
              telefono = $5, direccion = $6, activo = $7
       WHERE id = $8 RETURNING *`,
      [cedula, nombres, apellidos, email || null, telefono, direccion, activo, req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ ok: false, mensaje: 'Cliente no encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

router.delete('/:id', idValido, validate, async (req, res, next) => {
  try {
    const { rows } = await pool.query('DELETE FROM clientes WHERE id = $1 RETURNING id', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ ok: false, mensaje: 'Cliente no encontrado' });
    res.json({ ok: true, mensaje: 'Cliente eliminado correctamente' });
  } catch (err) { next(err); }
});

module.exports = router;
