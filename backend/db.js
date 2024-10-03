const { Pool } = require('pg'); // Importa il modulo pg

// Configura la connessione al database PostgreSQL usando Pool
const pool = new Pool({
  user: 'postgres',      // Sostituisci con il nome utente PostgreSQL
  host: 'localhost',     // L'host del database, di solito localhost o un IP specifico
  database: 'CasaMed',   // Il nome del tuo database
  password: 'postgres',  // La password dell'utente PostgreSQL
  port: 5432,            // La porta predefinita per PostgreSQL (5432)
});

// Test di connessione al database
pool.connect((err, client, release) => {
  if (err) {
    return console.error('Errore di connessione al database', err.stack);
  }
  console.log('Connesso al database PostgreSQL');
  release();  // Rilascia il client dopo la connessione
});

// Esporta la connessione per l'uso in altre parti dell'app
module.exports = pool;
