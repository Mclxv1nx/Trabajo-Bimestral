/**
 * Crea la base de datos vehiculos_db (si no existe) y ejecuta el esquema + seed.
 * Uso: npm run setup-db
 */
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const config = {
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'admin123',
};
const dbName = process.env.DB_NAME || 'vehiculos_db';

async function main() {
  // 1. Conectarse a la BD administrativa "postgres" para crear vehiculos_db
  const admin = new Client({ ...config, database: 'postgres' });
  await admin.connect();
  const exists = await admin.query('SELECT 1 FROM pg_database WHERE datname = $1', [dbName]);
  if (exists.rowCount === 0) {
    await admin.query(`CREATE DATABASE ${dbName}`);
    console.log(`✔ Base de datos "${dbName}" creada`);
  } else {
    console.log(`✔ Base de datos "${dbName}" ya existe`);
  }
  await admin.end();

  // 2. Ejecutar esquema + seed sobre vehiculos_db
  const db = new Client({ ...config, database: dbName });
  await db.connect();
  const schema = fs.readFileSync(path.join(__dirname, '..', 'src', 'db', 'schema.sql'), 'utf8');
  await db.query(schema);
  console.log('✔ Tablas creadas y datos de ejemplo insertados');
  await db.end();

  console.log('\nListo. Ejecuta "npm start" para levantar el API.');
}

main().catch((err) => {
  console.error('✖ Error configurando la base de datos:', err.message);
  process.exit(1);
});
