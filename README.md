# 🚗 Sistema de Gestión de Vehículos

Aplicación completa con **API REST (Node.js + Express + PostgreSQL)** documentada con **Swagger**, y **frontend Flutter** con Material 3 y notificaciones toast.

## Estructura

```
vehiculos-app/
├── backend/     API REST con Express, PostgreSQL y Swagger
└── frontend/    App Flutter (Material 3 + toastification)
```

## Base de datos

Tres tablas relacionadas, listas para crecer:

- **tipos_vehiculo** — catálogo de tipos (Sedán, SUV, Camioneta...)
- **clientes** — clientes con cédula única, email, teléfono y dirección
- **vehiculos** — placa única, marca, modelo, año, precio, kilometraje, estado (`DISPONIBLE`, `VENDIDO`, `RESERVADO`, `MANTENIMIENTO`), FK a tipo y a cliente (propietario)

Incluye índices, triggers de `updated_at` y datos de ejemplo.

## Requisitos

- Node.js 18+
- PostgreSQL corriendo en `localhost:5432` con usuario `postgres` y contraseña `admin123`
- Flutter SDK 3.22+

## 1. Levantar el backend

```bash
cd backend
npm install
npm run setup-db   # crea la BD vehiculos_db, tablas y datos de ejemplo
npm start          # levanta el API en http://localhost:3000
```

- **Swagger UI:** http://localhost:3000/api-docs
- **Health check:** http://localhost:3000/api/health

> La conexión se configura en `backend/.env` (host, puerto, usuario, contraseña, nombre de BD).

## 2. Levantar el frontend Flutter

```bash
cd frontend
flutter create . --platforms=windows,web,android   # genera las carpetas de plataforma
flutter pub get
flutter run -d chrome     # o -d windows, o un emulador
```

> **Importante según dónde ejecutes la app** (editar `lib/config/api_config.dart`):
> - Web / Windows / escritorio: `http://localhost:3000` (valor por defecto)
> - Emulador Android: `http://10.0.2.2:3000`
> - Dispositivo físico: `http://IP-DE-TU-PC:3000`

> Si usas **Flutter Web** y el navegador bloquea la conexión, el backend ya tiene CORS habilitado, no necesitas cambiar nada.

## Endpoints del API

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/health` | Estado del servicio y de la BD |
| GET/POST | `/api/tipos-vehiculo` | Listar / crear tipos |
| GET/PUT/DELETE | `/api/tipos-vehiculo/:id` | Obtener / actualizar / eliminar tipo |
| GET/POST | `/api/clientes` | Listar / crear clientes |
| GET/PUT/DELETE | `/api/clientes/:id` | Obtener / actualizar / eliminar cliente |
| GET/POST | `/api/vehiculos` | Listar (filtros: `tipo_id`, `estado`, `buscar`) / crear |
| GET/PUT/DELETE | `/api/vehiculos/:id` | Obtener / actualizar / eliminar vehículo |

Toda la documentación interactiva con ejemplos está en **Swagger** (`/api-docs`).

## Características destacadas

**Backend**
- Validación de datos con mensajes claros en español (express-validator)
- Manejo central de errores: duplicados → 409, FK en uso → 409, datos inválidos → 400
- Respuestas de vehículos enriquecidas con nombre del tipo y del propietario
- Búsqueda y filtros en el listado de vehículos

**Frontend (UX/UI)**
- Material 3 con esquema de color coherente
- Toasts de éxito/error/advertencia (estilo toastify) con barra de progreso
- Dashboard con métricas en vivo
- Confirmación antes de eliminar, estados vacíos con acción, estados de error con reintento
- Búsqueda en vivo, filtros por estado con chips, pull-to-refresh
- Botones claros y diferenciados (primario, tonal, outline, destructivo)
- Formularios validados con indicador de guardado

## Pruebas realizadas

El API fue probado de extremo a extremo contra PostgreSQL real: **26/26 pruebas pasaron**, incluyendo CRUD completo de las 3 entidades, validaciones (400), duplicados (409), llaves foráneas (409) y rutas inexistentes (404).
