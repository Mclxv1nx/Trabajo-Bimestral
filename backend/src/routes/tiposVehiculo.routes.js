const { Router } = require('express');
const { body, param } = require('express-validator');
const pool = require('../db/pool');
const validate = require('../middleware/validate');

const router = Router();

const reglas = [
  body('nombre').trim().notEmpty().withMessage('El nombre es obligatorio')
    .isLength({ max: 80 }).withMessage('Máximo 80 caracteres'),
  body('descripcion').optional({ nullable: true }).isString(),
  body('activo').optional().isBoolean().withMessage('activo debe ser true o false'),
];
const idValido = [param('id').isInt({ min: 1 }).withMessage('El id debe ser un entero positivo')];

/**
 * @openapi
 * /api/tipos-vehiculo:
 *   get:
 *     tags: [Tipos de Vehículo]
 *     summary: Listar todos los tipos de vehículo
 *     responses:
 *       200:
 *         description: Lista de tipos de vehículo
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { $ref: '#/components/schemas/TipoVehiculo' }
 *   post:
 *     tags: [Tipos de Vehículo]
 *     summary: Crear un tipo de vehículo
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/TipoVehiculoInput' }
 *     responses:
 *       201:
 *         description: Tipo creado
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/TipoVehiculo' }
 *       400: { $ref: '#/components/responses/BadRequest' }
 *       409: { $ref: '#/components/responses/Conflict' }
 */
router.get('/', async (req, res, next) => {
  try {
    const { rows } = await pool.query('SELECT * FROM tipos_vehiculo ORDER BY id');
    res.json(rows);
  } catch (err) { next(err); }
});

router.post('/', reglas, validate, async (req, res, next) => {
  try {
    const { nombre, descripcion = null, activo = true } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO tipos_vehiculo (nombre, descripcion, activo)
       VALUES ($1, $2, $3) RETURNING *`,
      [nombre, descripcion, activo]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
});

/**
 * @openapi
 * /api/tipos-vehiculo/{id}:
 *   get:
 *     tags: [Tipos de Vehículo]
 *     summary: Obtener un tipo de vehículo por id
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Tipo de vehículo
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/TipoVehiculo' }
 *       404: { $ref: '#/components/responses/NotFound' }
 *   put:
 *     tags: [Tipos de Vehículo]
 *     summary: Actualizar un tipo de vehículo
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/TipoVehiculoInput' }
 *     responses:
 *       200:
 *         description: Tipo actualizado
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/TipoVehiculo' }
 *       400: { $ref: '#/components/responses/BadRequest' }
 *       404: { $ref: '#/components/responses/NotFound' }
 *       409: { $ref: '#/components/responses/Conflict' }
 *   delete:
 *     tags: [Tipos de Vehículo]
 *     summary: Eliminar un tipo de vehículo
 *     description: Falla con 409 si existen vehículos asociados al tipo.
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200: { description: Tipo eliminado }
 *       404: { $ref: '#/components/responses/NotFound' }
 *       409: { $ref: '#/components/responses/Conflict' }
 */
router.get('/:id', idValido, validate, async (req, res, next) => {
  try {
    const { rows } = await pool.query('SELECT * FROM tipos_vehiculo WHERE id = $1', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ ok: false, mensaje: 'Tipo de vehículo no encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

router.put('/:id', [...idValido, ...reglas], validate, async (req, res, next) => {
  try {
    const { nombre, descripcion = null, activo = true } = req.body;
    const { rows } = await pool.query(
      `UPDATE tipos_vehiculo SET nombre = $1, descripcion = $2, activo = $3
       WHERE id = $4 RETURNING *`,
      [nombre, descripcion, activo, req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ ok: false, mensaje: 'Tipo de vehículo no encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

router.delete('/:id', idValido, validate, async (req, res, next) => {
  try {
    const { rows } = await pool.query('DELETE FROM tipos_vehiculo WHERE id = $1 RETURNING id', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ ok: false, mensaje: 'Tipo de vehículo no encontrado' });
    res.json({ ok: true, mensaje: 'Tipo de vehículo eliminado correctamente' });
  } catch (err) { next(err); }
});

module.exports = router;
