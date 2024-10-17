const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('./db'); // Importa il database
const router = express.Router();

// Middleware per autenticare l'utente tramite JWT
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (token == null) return res.sendStatus(401); // Se non c'è il token

  jwt.verify(token, "your_secret_key", (err, user) => { // Usa una variabile d'ambiente per la chiave segreta
    if (err) {
      console.error("Invalid token");
      return res.sendStatus(403); // Token non valido
    }
    req.user = user;
    //console.log("Authenticated successfully");
    next();
  });
}

// Rotta protetta per ottenere le specializzazioni del medico
router.get('/users/:userId/specializations', authenticateToken, async (req, res) => {
  const { userId } = req.params;

  // Assicura che l'utente possa accedere solo ai propri dati
  if (req.user.id !== parseInt(userId)) {
    console.error("Access denied to user's specializations");
    return res.status(403).json({ success: false, message: 'Access denied' });
  }

  try {
    // Cerca le specializzazioni nel database
    const result = await pool.query('SELECT specializations FROM users_type_1 WHERE id = $1', [userId]);
    if (result.rows.length > 0) {
      return res.json({ success: true, specializations: result.rows[0].specializations });
    }

    return res.status(404).json({ success: false, message: 'Specializations not found' });
  } catch (err) {
    console.error('Error fetching specializations', err);
    res.status(500).json({ success: false, message: 'Error fetching specializations' });
  }
});

// Rotta protetta per aggiornare le specializzazioni del medico
router.put('/users/:userId/specializations', authenticateToken, async (req, res) => {
  const { userId } = req.params;
  const { specializations } = req.body; // Assicurati che il corpo della richiesta contenga le specializzazioni

  // Assicura che l'utente possa accedere solo ai propri dati
  if (req.user.id !== parseInt(userId)) {
    console.error("Access denied to update user's specializations");
    return res.status(403).json({ success: false, message: 'Access denied' });
  }

  try {
    // Aggiorna le specializzazioni nel database
    await pool.query('UPDATE users_type_1 SET specializations = $1 WHERE id = $2', [specializations, userId]);
    return res.json({ success: true, message: 'Specializations updated successfully' });
  } catch (err) {
    console.error('Error updating specializations', err);
    res.status(500).json({ success: false, message: 'Error updating specializations' });
  }
});

module.exports = router;
