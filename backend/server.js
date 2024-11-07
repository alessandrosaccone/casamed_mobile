// server.js
const express = require('express');
const cors = require('cors');
const pool = require('./db'); // Assicurati di importare la connessione al database
const bcrypt = require('bcrypt');
const { check, validationResult } = require('express-validator'); // Importa check e validationResult
const { sendVerificationEmail, sendPasswordResetEmail } = require('./emailService');
const crypto = require('crypto');
const app = express();
const port = 3000;

// Importa le route
const registrationLoginRoutes = require('./registration_login');
const profileRoutes = require('./profile'); // Importa le route del profilo
const calendarRoutes = require('./calendar'); // Importa le route del calendario
const roleRoutes = require('./role'); // Importa le route per il controllo del ruolo

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // Supporto per dati URL-encoded
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

// Servire una pagina di reset della password per le richieste GET
app.get('/reset-password', (req, res) => {
  const token = req.query.token;
  
  if (!token) {
    return res.status(400).send('Token mancante o non valido.');
  }

  // Mostra una semplice pagina HTML per reimpostare la password
  res.send(`
    <html>
      <body>
        <form id="resetForm">
          <label>Nuova password:</label>
          <input type="password" id="newPassword" required />
          <button type="button" onclick="resetPassword()">Reimposta password</button>
        </form>
        
        <script>
          function resetPassword() {
            const newPassword = document.getElementById('newPassword').value;
            const token = "${token}";
            
            fetch('/reset-password', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json'
              },
              body: JSON.stringify({ token, newPassword })
            })
            .then(response => response.json())
            .then(data => {
              if (data.success) {
                alert('Password reimpostata con successo.');
              } else {
                alert(data.message || 'Errore durante la reimpostazione della password.');
              }
            })
            .catch(error => {
              console.error('Errore:', error);
            });
          }
        </script>
      </body>
    </html>
  `);
});

// Endpoint per la richiesta di reset password
app.post('/requestPasswordReset', check('email').isEmail().withMessage('Invalid email format.'), async (req, res) => {
  const { email } = req.body;

  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    // Controlla se l'email esiste nel database
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Email not found.' });
    }

    const resetToken = generateResetToken();
    const resetExpiry = new Date(Date.now() + 3600000); // Imposta la scadenza a 1 ora

    // Salva il token e la scadenza nel database
    await pool.query('UPDATE users SET reset_token = $1, reset_token_expiry = $2 WHERE email = $3', [resetToken, resetExpiry, email]);

    const resetLink = `http://localhost:3000/reset-password?token=${resetToken}`;
    await sendPasswordResetEmail(email, resetLink);

    res.json({ success: true, message: 'Password reset email sent. Please check your inbox.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Error sending password reset email.' });
  }
});

// Endpoint per il reset della password
app.post('/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;

  if (!token || !newPassword) {
    return res.status(400).json({ success: false, message: 'Token and new password are required.' });
  }

  try {
    // Verifica il token e la sua scadenza
    const result = await pool.query('SELECT * FROM users WHERE reset_token = $1 AND reset_token_expiry > NOW()', [token]);
    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid or expired token.' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE users SET pass = $1, reset_token = NULL, reset_token_expiry = NULL WHERE reset_token = $2', [hashedPassword, token]);

    res.json({ success: true, message: 'Password has been reset successfully.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Error resetting password.' });
  }
});

// Avvia il server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});



