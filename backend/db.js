const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const connectionString = process.env.DATABASE_URL;

const pool = connectionString
  ? new Pool({ connectionString })
  : new Pool({
      host: process.env.PGHOST || 'localhost',
      port: parseInt(process.env.PGPORT || '5432', 10),
      database: process.env.PGDATABASE || 'gestion_cours',
      user: process.env.PGUSER || 'postgres',
      password: process.env.PGPASSWORD || 'postgres',
    });

let isInitialized = false;

// Initialisation automatique des tables au démarrage
async function initDb() {
  if (isInitialized) return;
  try {
    const client = await pool.connect();
    console.log('✅ Connecté avec succès à PostgreSQL');
    
    // Lire le schéma SQL
    const schemaPath = path.join(__dirname, 'schema.sql');
    if (fs.existsSync(schemaPath)) {
      const sql = fs.readFileSync(schemaPath, 'utf8');
      await client.query(sql);
      console.log('✅ Schéma SQL initialisé / vérifié avec succès');
    }
    client.release();
    isInitialized = true;
  } catch (err) {
    console.warn('⚠️ Avertissement PostgreSQL :', err.message);
    console.warn('Vérifiez que PostgreSQL est bien démarré et que la base "gestion_cours" existe.');
  }
}

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
  initDb,
};
