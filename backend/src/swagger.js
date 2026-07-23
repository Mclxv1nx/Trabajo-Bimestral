const swaggerJsdoc = require('swagger-jsdoc');
const path = require('path');

const options = {
  definition: {
    openapi: '3.0.3',
    info: {
      title: 'API de Gestión de Vehículos',
      version: '1.0.0',
      description:
        'API REST para la gestión de **tipos de vehículo**, **vehículos** y **clientes**. ' +
        'Construida con Node.js, Express y PostgreSQL.',
      contact: { name: 'Adrián Urresta', email: 'sanchezadrianu@gmail.com' },
    },
    servers: [{ url: 'http://localhost:3000', description: 'Servidor local' }],
    tags: [
      { name: 'Tipos de Vehículo', description: 'CRUD de tipos de vehículo' },
      { name: 'Vehículos', description: 'CRUD de vehículos' },
      { name: 'Clientes', description: 'CRUD de clientes' },
      { name: 'Sistema', description: 'Estado del servicio' },
    ],
    components: {
      schemas: {
        TipoVehiculo: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            nombre: { type: 'string', example: 'SUV' },
            descripcion: { type: 'string', example: 'Vehículo utilitario deportivo' },
            activo: { type: 'boolean', example: true },
            created_at: { type: 'string', format: 'date-time' },
            updated_at: { type: 'string', format: 'date-time' },
          },
        },
        TipoVehiculoInput: {
          type: 'object',
          required: ['nombre'],
          properties: {
            nombre: { type: 'string', example: 'SUV' },
            descripcion: { type: 'string', example: 'Vehículo utilitario deportivo' },
            activo: { type: 'boolean', example: true },
          },
        },
        Cliente: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            cedula: { type: 'string', example: '1004567890' },
            nombres: { type: 'string', example: 'Juan Carlos' },
            apellidos: { type: 'string', example: 'Pérez Gómez' },
            email: { type: 'string', example: 'juan.perez@mail.com' },
            telefono: { type: 'string', example: '0991234567' },
            direccion: { type: 'string', example: 'Av. Atahualpa 12-34, Ibarra' },
            activo: { type: 'boolean', example: true },
            created_at: { type: 'string', format: 'date-time' },
            updated_at: { type: 'string', format: 'date-time' },
          },
        },
        ClienteInput: {
          type: 'object',
          required: ['cedula', 'nombres', 'apellidos'],
          properties: {
            cedula: { type: 'string', example: '1004567890' },
            nombres: { type: 'string', example: 'Juan Carlos' },
            apellidos: { type: 'string', example: 'Pérez Gómez' },
            email: { type: 'string', example: 'juan.perez@mail.com' },
            telefono: { type: 'string', example: '0991234567' },
            direccion: { type: 'string', example: 'Av. Atahualpa 12-34, Ibarra' },
            activo: { type: 'boolean', example: true },
          },
        },
        Vehiculo: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            placa: { type: 'string', example: 'PBA-1234' },
            marca: { type: 'string', example: 'Toyota' },
            modelo: { type: 'string', example: 'Corolla' },
            anio: { type: 'integer', example: 2023 },
            color: { type: 'string', example: 'Blanco' },
            precio: { type: 'number', example: 24500.0 },
            kilometraje: { type: 'integer', example: 12000 },
            estado: {
              type: 'string',
              enum: ['DISPONIBLE', 'VENDIDO', 'RESERVADO', 'MANTENIMIENTO'],
              example: 'DISPONIBLE',
            },
            tipo_id: { type: 'integer', example: 1 },
            cliente_id: { type: 'integer', nullable: true, example: null },
            tipo_nombre: { type: 'string', example: 'Sedán' },
            cliente_nombre: { type: 'string', nullable: true, example: 'Juan Carlos Pérez Gómez' },
            created_at: { type: 'string', format: 'date-time' },
            updated_at: { type: 'string', format: 'date-time' },
          },
        },
        VehiculoInput: {
          type: 'object',
          required: ['placa', 'marca', 'modelo', 'anio', 'tipo_id'],
          properties: {
            placa: { type: 'string', example: 'PBA-1234' },
            marca: { type: 'string', example: 'Toyota' },
            modelo: { type: 'string', example: 'Corolla' },
            anio: { type: 'integer', example: 2023 },
            color: { type: 'string', example: 'Blanco' },
            precio: { type: 'number', example: 24500.0 },
            kilometraje: { type: 'integer', example: 12000 },
            estado: {
              type: 'string',
              enum: ['DISPONIBLE', 'VENDIDO', 'RESERVADO', 'MANTENIMIENTO'],
              example: 'DISPONIBLE',
            },
            tipo_id: { type: 'integer', example: 1 },
            cliente_id: { type: 'integer', nullable: true, example: null },
          },
        },
        Error: {
          type: 'object',
          properties: {
            ok: { type: 'boolean', example: false },
            mensaje: { type: 'string', example: 'Descripción del error' },
          },
        },
      },
      responses: {
        NotFound: {
          description: 'Recurso no encontrado',
          content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
        },
        BadRequest: {
          description: 'Datos inválidos',
          content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
        },
        Conflict: {
          description: 'Conflicto (duplicado o registro relacionado)',
          content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
        },
      },
    },
  },
  apis: [path.join(__dirname, 'routes', '*.js'), path.join(__dirname, 'index.js')],
};

module.exports = swaggerJsdoc(options);
