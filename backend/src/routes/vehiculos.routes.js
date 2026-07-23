const { Router } = require('express');
const { body, param, query } = require('express-validator');
const pool = require('../db/pool');
const validate = require('../middleware/validate');

const router = Router();

const ESTADOS = ['DISPONIBLE', 'VENDIDO', 'RESERVADO', 'MANTENIMIENTO'];

const reglas = [
  body('placa').trim().notEmpty().withMessage('La placa es obligatoria')
    .isLength({ max: 15 }).withMessage('Máximo 15 caracteres'),
  body('marca').trim().notEmpty().withMessage('La marca es obligatoria'),
  body('modelo').trim().notEmpty().withMessage('El modelo es obligatorio'),
  body('anio').isInt({ min: 1900, max: 2100 }).withMessage('El año debe estar entre 1900 y 2100'),
  body('color').optional({ nullable: true, checkFalsy: true }).isLength({ max: 40 }),
  body('precio').optional({ nullable: true }).isFloat({ min: 0 }).withMessage('El precio debe ser >= 0'),
  body('kilometraje').optional({ nullable: true }).isInt({ min: 0 }).withMessage('El kilometraje debe ser >= 0'),
  body('estado').optional().isIn(ESTADOS).withMessage(`Estado inválido. Valores: ${ESTADOS.join(', ')}`),
  body('tipo_id').isInt({ min: 1 }).withMessage('tipo_id es obligatorio y debe ser un entero positivo'),
  body('cliente_id').optional({ nullable: true }).isInt({ min: 1 }).withMessage('cliente_id debe ser un entero positivo'),
];
const idValido = [param('id').isInt({ min: 1 }).withMessage('El id debe ser un entero positivo')];

const SELECT_VEHICULO = `
  SELECT v.*,
         t.nombre AS tipo_nombre,
         CASE WHEN c.id IS NULL THEN NULL
              ELSE c.nombres || ' ' || c.apellidos END AS cliente_nombre
  FROM vehiculos v
  JOIN tipos_vehiculo t ON t.id = v.tipo_id
  LEFT JOIN clientes c ON c.id = v.cliente_id`;

/**
 * @openapi
 * /api/vehiculos:
 *   get:
 *     tags: [Vehículos]
 *     summary: Listar vehículos (con filtros opcionales)
 *     parameters:
 *       - in: query
 *         name: tipo_id
 *         schema: { type: integer }
 *         description: Filtrar por tipo de vehículo
 *       - in: query
 *         name: estado
 *         schema: { type: string, enum: [DISPONIBLE, VENDIDO, RESERVADO, MANTENIMIENTO] }
 *         description: Filtrar por estado
 *       - in: query
 *         name: buscar
 *         schema: { type: string }
 *         description: Búsqueda por placa, marca o modelo
 *     responses:
 *       200:
 *         description: Lista de vehículos con datos del tipo y cliente
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { $ref: '#/components/schemas/Vehiculo' }
 *   post:
 *     tags: [Vehículos]
 *     summary: Registrar un vehículo
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/VehiculoInput' }
 *     responses:
 *       201:
 *         description: Vehículo creado
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Vehiculo' }
 *       400: { $ref: '#/components/responses/BadRequest' }
 *       409: { $ref: '#/components/responses/Conflict' }
 */
router.get(
  '/',
  [
    query('tipo_id').optional().isInt({ min: 1 }),
    query('estado').optional().isIn(ESTADOS),
    query('buscar').optional().isString(),
  ],
  validate,
  async (req, res, next) => {
    try {
      const condiciones = [];
      const valores = [];
      if (req.query.tipo_id) {
        valores.push(req.query.tipo_id);
        condiciones.push(`v.tipo_id = $${valores.length}`);
      }
      if (req.query.estado) {
        valores.push(req.query.estado);
        condiciones.push(`v.estado = $${valores.length}`);
      }
      if (req.query.buscar) {
        valores.push(`%${req.query.buscar}%`);
        condiciones.push(
          `(v.placa ILIKE $${valores.length} OR v.marca ILIKE $${valores.length} OR v.modelo ILIKE $${valores.length})`
        );
      }
      const where = condiciones.length ? ` WHERE ${condiciones.join(' AND ')}` : '';
      const { rows } = await pool.query(`${SELECT_VEHICULO}${where} ORDER BY v.id`, valores);
      res.json(rows);
    } catch (err) { next(err); }
  }
);

router.post('/', reglas, validate, async (req, res, next) => {
  try {
    const {
      placa, marca, modelo, anio, color = null, precio = null,
      kilometraje = 0, estado = 'DISPONIBLE', tipo_id, cliente_id = null,
    } = req.body;
    const insert = await pool.query(
      `INSERT INTO vehiculos (placa, marca, modelo, anio, color, precio, kilometraje, estado, tipo_id, cliente_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id`,
      [placa.toUpperCase(), marca, modelo, anio, color, precio, kilometraje, estado, tipo_id, cliente_id]
    );
    const { rows } = await pool.query(`${SELECT_VEHICULO} WHERE v.id = $1`, [insert.rows[0].id]);
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
});

/**
 * @openapi
 * /api/vehiculos/{id}:
 *   get:
 *     tags: [Vehículos]
 *     summary: Obtener un vehículo por id
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Vehículo
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Vehiculo' }
 *       404: { $ref: '#/components/responses/NotFound' }
 *   put:
 *     tags: [Vehículos]
 *     summary: Actualizar un vehículo
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/VehiculoInput' }
 *     responses:
 *       200:
 *         description: Vehículo actualizado
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Vehiculo' }
 *       400: { $ref: '#/components/responses/BadRequest' }
 *       404: { $ref: '#/components/responses/NotFound' }
 *       409: { $ref: '#/components/responses/Conflict' }
 *   delete:
 *     tags: [Vehículos]
 *     summary: Eliminar un vehículo
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200: { description: Vehículo eliminado }
 *       404: { $ref: '#/components/responses/NotFound' }
 */
router.get('/:id', idValido, validate, async (req, res, next) => {
  try {
    const { rows } = await pool.query(`${SELECT_VEHICULO} WHERE v.id = $1`, [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ ok: false, mensaje: 'Vehículo no encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

router.put('/:id', [...idValido, ...reglas], validate, async (req, res, next) => {
  try {
    const {
      placa, marca, modelo, anio, color = null, precio = null,
      kilometraje = 0, estado = 'DISPONIBLE', tipo_id, cliente_id = null,
    } = req.body;
    const update = await pool.query(
      `UPDATE vehiculos SET placa = $1, marca = $2, modelo = $3, anio = $4, color = $5,
              precio = $6, kilometraje = $7, estado = $8, tipo_id = $9, cliente_id = $10
       WHERE id = $11 RETURNING id`,
      [placa.toUpperCase(), marca, modelo, anio, color, precio, kilometraje, estado, tipo_id, cliente_id, req.params.id]
    );
    if (update.rows.length === 0) return res.status(404).json({ ok: false, mensaje: 'Vehículo no encontrado' });
    const { rows } = await pool.query(`${SELECT_VEHICULO} WHERE v.id = $1`, [req.params.id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
});

router.delete('/:id', idValido, validate, async (req, res, next) => {
  try {
    const { rows } = await pool.query('DELETE FROM vehiculos WHERE id = $1 RETURNING id', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ ok: false, mensaje: 'Vehículo no encontrado' });
    res.json({ ok: true, mensaje: 'Vehículo eliminado correctamente' });
  } catch (err) { next(err); }
});

module.exports = router;
