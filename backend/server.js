// server.js
const express = require('express');
const cors = require('cors');
const pool = require('./db'); // Assicurati di importare la connessione al database
const app = express();
const port = 3000;

// Importa le route
const registrationLoginRoutes = require('./registration_login');
const profileRoutes = require('./profile'); // Importa le route del profilo
const calendarRoutes = require('./calendar'); // Importa le route del calendario
const roleRoutes = require('./role'); // Importa le route per il controllo del ruolo

// Middleware
app.use(express.json());
app.use(cors());

// Usa le route
app.use('/', registrationLoginRoutes);  // Route per login/registrazione
app.use('/profile', profileRoutes);     // Route per il profilo
app.use('/calendar', calendarRoutes);   // Route per il calendario
app.use('/', roleRoutes); // Usa le route per il controllo del ruolo

// Endpoint per la verifica dell'email
app.get('/verify-email', async (req, res) => {
  const { token } = req.query; // Prendi il token dalla query string

  if (!token) {
    return res.status(400).json({ success: false, message: 'Token is required.' });
  }

  try {
    // Verifica se il token esiste nel database
    const result = await pool.query('SELECT * FROM users WHERE verification_token = $1', [token]);

    if (result.rows.length > 0) {
      // Se il token è valido, attiva l'account (modifica il campo attivazione in base alla tua struttura)
      await pool.query('UPDATE users SET is_verified = true, verification_token = NULL WHERE verification_token = $1', [token]);
      return res.json({ success: true, message: 'Email verified successfully!' });
    } else {
      return res.status(400).json({ success: false, message: 'Invalid token.' });
    }
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Error verifying email.' });
  }
});

// Avvia il server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});


