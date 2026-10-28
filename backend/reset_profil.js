const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  port: parseInt(process.env.PGPORT || '5432', 10),
  database: process.env.PGDATABASE || 'gestion_cours',
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || 'postgres',
});

async function reset() {
  try {
    await pool.query("UPDATE config SET valeur = '' WHERE cle = 'ProfNom'");
    await pool.query("INSERT INTO config (cle, valeur) VALUES ('isConfigured', 'false') ON CONFLICT (cle) DO UPDATE SET valeur = 'false'");
    await pool.query("INSERT INTO config (cle, valeur) VALUES ('ProfTitre', 'Prof.') ON CONFLICT (cle) DO UPDATE SET valeur = 'Prof.'");
    await pool.query("INSERT INTO config (cle, valeur) VALUES ('ProfSpecialite', '') ON CONFLICT (cle) DO UPDATE SET valeur = ''");
    await pool.query("INSERT INTO config (cle, valeur) VALUES ('ProfTelephone', '') ON CONFLICT (cle) DO UPDATE SET valeur = ''");
    await pool.query("INSERT INTO config (cle, valeur) VALUES ('ProfEmail', '') ON CONFLICT (cle) DO UPDATE SET valeur = ''");
    await pool.query("INSERT INTO config (cle, valeur) VALUES ('PinCode', '') ON CONFLICT (cle) DO UPDATE SET valeur = ''");
    await pool.query("INSERT INTO config (cle, valeur) VALUES ('Avatar', 'school') ON CONFLICT (cle) DO UPDATE SET valeur = 'school'");
    console.log('RESET_SUCCESS');
  } catch (err) {
    console.error('RESET_ERROR:', err);
  } finally {
    await pool.end();
  }
}

reset();
