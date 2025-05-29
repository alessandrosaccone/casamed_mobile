const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const pool = require('./db');
const bcrypt = require('bcrypt');
const { check, validationResult } = require('express-validator');
const { sendVerificationEmail, sendPasswordResetEmail } = require('./emailService');
const crypto = require('crypto');
const app = express();

const SECRET_KEY = 'your_secret_key';

app.use(express.json());
app.use(cors());

// Funzione per generare un token di verifica
const generateVerificationToken = () => {
  return crypto.randomBytes(20).toString('hex');
};

// Funzione per generare un token di reset della password
const generateResetToken = () => {
  return crypto.randomBytes(20).toString('hex');
};


// Registration (Sign Up)
app.post('/register', [
  check('email').isEmail().withMessage('Invalid email format.'),
  check('pass')
    .isLength({ min: 12 }).withMessage('Password must be at least 12 characters long.')
    .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter.')
    .matches(/[a-z]/).withMessage('Password must contain at least one lowercase letter.')
    .matches(/[0-9]/).withMessage('Password must contain at least one number.')
    .matches(/[^A-Za-z0-9]/).withMessage('Password must contain at least one special character.'),
  check('vat_number').optional().matches(/^[A-Z]{2}\d{11}$/).withMessage('Invalid VAT number format.'),
  check('iban').optional().matches(/^[A-Z]{2}\d{2}[A-Z0-9]{1,30}$/).withMessage('Invalid IBAN format.')
], async (req, res) => {
  const {
    email,
    pass,
    first_name,
    last_name,
    birth_date,
    address,
    vat_number,
    professional_insurance_number,
    iban,
    professional_association_registration,
    is_nurse // booleano: true se infermiere, false se medico
  } = req.body;

  let role;

  // Determina il ruolo numerico
  if (vat_number && professional_insurance_number) {
    role = is_nurse === true ? 1 : 2; // 1 = infermiere, 2 = medico
  } else {
    role = 0; // 0 = paziente
    
    console.log("Assigned role:", role);
  }

  


  // Validazione base dei campi
  if (role === 0) {
    if (!first_name || !last_name || !birth_date || !address) {
      console.log("Assigned role:", role);
      return res.status(400).json({ success: false, message: 'Missing required fields for patient.' });
    }
  } else {
    if (
      !first_name || !last_name || !birth_date || !address ||
      !vat_number || !professional_insurance_number || !iban || !professional_association_registration
    ) {
      return res.status(400).json({ success: false, message: 'Missing required fields for healthcare professional.' });
    }
  }

  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const hashedPassword = await bcrypt.hash(pass, 10);

    // Inserimento nella tabella `users`
    const result = await pool.query(
      `INSERT INTO users (
        email,
        pass,
        first_name,
        last_name,
        birth_date,
        address,
        role,
        vat_number,
        professional_insurance_number,
        iban,
        professional_association_registration,
        is_verified
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING id`,
      [
        email,
        hashedPassword,
        first_name,
        last_name,
        birth_date,
        address,
        role,
        vat_number || null,
        professional_insurance_number || null,
        iban || null,
        professional_association_registration || null,
        false
      ]
    );

    // Token di verifica e email
    const verificationToken = generateVerificationToken();
    const verificationLink = `http://localhost:3000/verify-email?token=${verificationToken}`;

    await pool.query('UPDATE users SET verification_token = $1 WHERE email = $2', [verificationToken, email]);
    await sendVerificationEmail(email, verificationLink);

    res.json({
      success: true,
      message: 'User registered successfully. Please check your email to verify your account.'
    });

    console.log("User registered successfully");
  } catch (err) {
    console.error('Detailed error:', err);
    res.status(500).json({ success: false, message: 'Error during registration.' });
  }
});



// Login (Sign In)
app.post('/login', async (req, res) => {
  const { email, pass } = req.body;

  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (result.rows.length > 0) {
      const user = result.rows[0];

      if (!user.is_verified) {
        return res.status(403).json({ success: false, message: 'Please verify your email before logging in.' });
      }

      const validPassword = await bcrypt.compare(pass, user.pass);

      if (validPassword) {
        const token = jwt.sign({ id: user.id, email: user.email }, SECRET_KEY, { expiresIn: '1h' });
        res.json({ success: true, message: 'Login successful.', userId: user.id, token });
        console.log("Login successful");
      } else {
        res.status(401).json({ success: false, message: 'Incorrect password.' });
      }
    } else {
      res.status(404).json({ success: false, message: 'User not found.' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Error during login.' });
  }
});

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

module.exports = app;