const express = require('express');
const pool = require('./db'); // Assicurati che questo punti correttamente alla connessione al database
const router = express.Router();
const authenticateToken = require('./authMiddleware'); // Importa il middleware

// Endpoint per ottenere i medici (ruolo 1) protetto dal middleware di autenticazione
router.get('/discovery', authenticateToken, async (req, res) => {
  try {
    // Query per selezionare ID, nome e cognome degli utenti con ruolo 1 (tabella users_type_1)
    const result = await pool.query(`
      SELECT id, first_name, last_name 
      FROM users_type_1
    `);

    // Invia la lista dei medici (ID, nome e cognome)
    res.json({ success: true, doctors: result.rows });
  } catch (err) {
    console.error('Errore durante il recupero dei dati:', err);
    res.status(500).json({ success: false, message: 'Errore durante il recupero dei dati.' });
  }
});

module.exports = router;
