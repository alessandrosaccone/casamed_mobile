const express = require('express');
const pool = require('./db'); // Importa il database
const authenticateToken = require('./authMiddleware'); // Importa il middleware di autenticazione
const router = express.Router();

// Rotta protetta per il profilo
router.get('/:userId', authenticateToken, async (req, res) => {
  const { userId } = req.params;

  // Assicura che l'utente possa accedere solo ai propri dati
  if (req.user.id !== parseInt(userId)) {
    console.log("Not authorized to see the profile");
    return res.status(403).json({ success: false, message: 'Access denied' });
  }

  try {
    let result;

    // Cerca l'utente nel database (es. pazienti)
    // result = await pool.query('SELECT * FROM users_type_0 WHERE id = $1', [userId]);
    // if (result.rows.length > 0) {
    //   return res.json({ success: true, role: 0, userData: result.rows[0] });
    // }
    result = await pool.query('SELECT * FROM users WHERE id = $1 and role = 0', [userId]);
    if (result.rows.length > 0) {
      return res.json({ success: true, role: 0, userData: result.rows[0] });
    }
    // Cerca l'utente nel database (es. healthcare experts)
    result = await pool.query('SELECT * FROM users WHERE id = $1 and role = 1', [userId]);
    if (result.rows.length > 0) {
      return res.json({ success: true, role: 1, userData: result.rows[0] });
    }
    result = await pool.query('SELECT * FROM users WHERE id = $1 and role = 2', [userId]);
    if (result.rows.length > 0) {
      return res.json({ success: true, role: 2, userData: result.rows[0] });
    }

    return res.status(404).json({ success: false, message: 'User not found' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Error fetching user data' });
  }
});

module.exports = router;