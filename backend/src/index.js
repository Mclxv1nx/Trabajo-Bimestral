const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
require('dotenv').config();

const swaggerSpec = require('./swagger');
const pool = require('./db/pool');
const errorHandler = require('./middleware/errorHandler');

const tiposVehiculoRoutes = require('./routes/tiposVehiculo.routes');
const vehiculosRoutes = require('./routes/vehiculos.routes');
const clientesRoutes = require('./routes/clientes.routes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Log simple de peticiones
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.originalUrl}`);
  next();
});

/**
 * @openapi
 * /api/health:
 *   get:
 *     tags: [Sistema]
 *     summary: Estado del servicio y conexión a la base de datos
 *     responses:
 *       200:
 *         description: Servicio operativo
 *       503:
 *         description: Sin conexión a la base de datos
 */
app.get('/api/health', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT NOW() AS ahora');
    res.json({ ok: true, servicio: 'vehiculos-api', baseDatos: 'conectada', hora: rows[0].ahora });
  } catch (err) {
    res.status(503).json({ ok: false, servicio: 'vehiculos-api', baseDatos: 'sin conexión', error: err.message });
  }
});

// Rutas del API
app.use('/api/tipos-vehiculo', tiposVehiculoRoutes);
app.use('/api/vehiculos', vehiculosRoutes);
app.use('/api/clientes', clientesRoutes);

// Documentación Swagger
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customSiteTitle: 'API Vehículos — Documentación',
  swaggerOptions: { docExpansion: 'list', defaultModelsExpandDepth: 1 },
}));
app.get('/api-docs.json', (req, res) => res.json(swaggerSpec));

// Raíz: redirigir a la documentación
app.get('/', (req, res) => res.redirect('/api-docs'));

// 404 para rutas no definidas
app.use((req, res) => {
  res.status(404).json({ ok: false, mensaje: `Ruta no encontrada: ${req.method} ${req.originalUrl}` });
});

app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`✔ API de Vehículos corriendo en  http://localhost:${PORT}`);
  console.log(`✔ Documentación Swagger en       http://localhost:${PORT}/api-docs`);
});
