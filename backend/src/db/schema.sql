-- =====================================================
-- Esquema de base de datos: vehiculos_db
-- Tablas: tipos_vehiculo, clientes, vehiculos
-- =====================================================

CREATE TABLE IF NOT EXISTS tipos_vehiculo (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(80) NOT NULL UNIQUE,
    descripcion TEXT,
    activo      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clientes (
    id         SERIAL PRIMARY KEY,
    cedula     VARCHAR(20) NOT NULL UNIQUE,
    nombres    VARCHAR(100) NOT NULL,
    apellidos  VARCHAR(100) NOT NULL,
    email      VARCHAR(150) UNIQUE,
    telefono   VARCHAR(20),
    direccion  TEXT,
    activo     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vehiculos (
    id         SERIAL PRIMARY KEY,
    placa      VARCHAR(15) NOT NULL UNIQUE,
    marca      VARCHAR(80) NOT NULL,
    modelo     VARCHAR(80) NOT NULL,
    anio       INTEGER NOT NULL CHECK (anio BETWEEN 1900 AND 2100),
    color      VARCHAR(40),
    precio     NUMERIC(12, 2) CHECK (precio >= 0),
    kilometraje INTEGER DEFAULT 0 CHECK (kilometraje >= 0),
    estado     VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE'
               CHECK (estado IN ('DISPONIBLE', 'VENDIDO', 'RESERVADO', 'MANTENIMIENTO')),
    tipo_id    INTEGER NOT NULL REFERENCES tipos_vehiculo(id) ON DELETE RESTRICT,
    cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vehiculos_tipo    ON vehiculos(tipo_id);
CREATE INDEX IF NOT EXISTS idx_vehiculos_cliente ON vehiculos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_vehiculos_estado  ON vehiculos(estado);

-- Trigger para mantener updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_tipos_updated ON tipos_vehiculo;
CREATE TRIGGER trg_tipos_updated BEFORE UPDATE ON tipos_vehiculo
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_clientes_updated ON clientes;
CREATE TRIGGER trg_clientes_updated BEFORE UPDATE ON clientes
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_vehiculos_updated ON vehiculos;
CREATE TRIGGER trg_vehiculos_updated BEFORE UPDATE ON vehiculos
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================
-- Datos de ejemplo (seed)
-- =====================================================
INSERT INTO tipos_vehiculo (nombre, descripcion) VALUES
    ('Sedán',      'Vehículo de pasajeros con maletero separado'),
    ('SUV',        'Vehículo utilitario deportivo, mayor altura y espacio'),
    ('Camioneta',  'Vehículo con área de carga descubierta (pickup)'),
    ('Motocicleta','Vehículo de dos ruedas'),
    ('Camión',     'Vehículo pesado para transporte de carga'),
    ('Bus',        'Vehículo para transporte masivo de pasajeros')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO clientes (cedula, nombres, apellidos, email, telefono, direccion) VALUES
    ('1004567890', 'Juan Carlos', 'Pérez Gómez',   'juan.perez@mail.com',   '0991234567', 'Av. Atahualpa 12-34, Ibarra'),
    ('1003216549', 'María José',  'Andrade Ruiz',  'maria.andrade@mail.com','0987654321', 'Calle Bolívar 5-67, Otavalo'),
    ('1712345678', 'Luis Alberto','Cevallos Mora', 'luis.cevallos@mail.com','0965432187', 'Av. El Retorno 8-90, Ibarra')
ON CONFLICT (cedula) DO NOTHING;

INSERT INTO vehiculos (placa, marca, modelo, anio, color, precio, kilometraje, estado, tipo_id, cliente_id) VALUES
    ('PBA-1234', 'Toyota',    'Corolla',   2023, 'Blanco', 24500.00, 12000, 'DISPONIBLE',    1, NULL),
    ('IBC-5678', 'Chevrolet', 'Tracker',   2024, 'Rojo',   28900.00, 5000,  'RESERVADO',     2, 1),
    ('PCD-9012', 'Ford',      'Ranger',    2022, 'Gris',   35200.00, 34000, 'VENDIDO',       3, 2),
    ('IBE-3456', 'Yamaha',    'MT-03',     2024, 'Negro',  6800.00,  1500,  'DISPONIBLE',    4, NULL),
    ('PFG-7890', 'Hino',      'Serie 500', 2021, 'Blanco', 78000.00, 89000, 'MANTENIMIENTO', 5, 3)
ON CONFLICT (placa) DO NOTHING;
