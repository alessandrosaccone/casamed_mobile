const express = require('express');
const jwt = require('jsonwebtoken'); // Commentato per evitare errori, scommentalo quando necessario
const cors = require('cors');
const pool = require('./db'); // Importa la connessione al database da db.js
const bcrypt = require('bcrypt'); // Per l'hashing delle password
const { check, validationResult } = require('express-validator'); // Importa le funzioni di express-validator
const { sendVerificationEmail } = require('./emailService'); // Importa il servizio email
const crypto = require('crypto'); // Per generare un token di verifica
const app = express();

const SECRET_KEY = 'your_secret_key'; //SECURITY LEAK

// Middleware
app.use(express.json());
app.use(cors());

// Funzione per generare un token di verifica
const generateVerificationToken = () => {
  return crypto.randomBytes(20).toString('hex');
};

// Registration (Sign Up)
app.post('/register', [
  // Verifica del formato dell'email
  check('email').isEmail().withMessage('Invalid email format.'),
  // Verifica della password
  check('pass')
    .isLength({ min: 12 }).withMessage('Password must be at least 12 characters long.')
    .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter.')
    .matches(/[a-z]/).withMessage('Password must contain at least one lowercase letter.')
    .matches(/[0-9]/).withMessage('Password must contain at least one number.')
    .matches(/[^A-Za-z0-9]/).withMessage('Password must contain at least one special character.'),
  // Verifica del formato della partita IVA
  check('vat_number')
    .optional() // Rendi il campo opzionale
    .matches(/^[A-Z]{2}\d{11}$/).withMessage('Invalid VAT number format.'), // Controllo del formato della partita IVA (es. IT12345678901)
  // Verifica del formato IBAN
  check('iban')
    .optional() // Se è opzionale, altrimenti rimuovi questa linea
    .matches(/^[A-Z]{2}\d{2}[A-Z0-9]{1,30}$/).withMessage('Invalid IBAN format.') // Regex per controllare il formato IBAN
], async (req, res) => {
  const {
    email, pass, role, first_name, last_name, birth_date, address, vat_number, professional_insurance_number, iban, professional_association_registration
  } = req.body;

  // Verifica che email e password siano forniti
  if (!email || !pass) {
    return res.status(400).json({ success: false, message: 'Email and password are required.' });
  }

  // Controlla i campi richiesti in base al ruolo
  if (role === 0) {
    if (!first_name || !last_name || !birth_date) {
      return res.status(400).json({ success: false, message: 'First name, last name, and birth date are required for role 0.' });
    }
  } else if (role === 1) {
    if (!first_name || !last_name || !birth_date || !address || !vat_number || !professional_insurance_number || !iban || !professional_association_registration) {
      return res.status(400).json({ success: false, message: 'All fields are required for role 1 (professional).' });
    }
  } else {
    return res.status(400).json({ success: false, message: 'Invalid role.' });
  }

  // Controlla gli errori di validazione
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    // Hash the password before saving it
    const hashedPassword = await bcrypt.hash(pass, 10);
    let result;

    if (role === 0) {
      // Insert data for role 0 user
      result = await pool.query(
        'INSERT INTO users_type_0 (email, pass, first_name, last_name, birth_date) VALUES ($1, $2, $3, $4, $5) RETURNING id',
        [email, hashedPassword, first_name, last_name, birth_date]
      );
    } else if (role === 1) {
      // Insert data for role 1 user with additional fields
      result = await pool.query(
        `INSERT INTO users_type_1 (email, pass, first_name, last_name, birth_date, address, vat_number, professional_insurance_number, iban, professional_association_registration)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id`,
        [email, hashedPassword, first_name, last_name, birth_date, address, vat_number, professional_insurance_number, iban, professional_association_registration]
      );
    }

    // Genera il token di verifica
    const verificationToken = generateVerificationToken();
    const verificationLink = `http://localhost:3000/verify-email?token=${verificationToken}`;
    
    // Salva il token di verifica nel database (modifica questa parte in base alla tua struttura del database)
    await pool.query('UPDATE users SET verification_token = $1 WHERE email = $2', [verificationToken, email]);

    // Invia l'email di verifica
    await sendVerificationEmail(email, verificationLink);

    // Send success response with the user ID
    res.json({ success: true, message: 'User registered successfully. Please check your email to verify your account.', userId: result.rows[0].id });
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
    // Look for the user by email
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (result.rows.length > 0) {
      const user = result.rows[0];

      // Compare the entered password with the hashed password in the DB
      const validPassword = await bcrypt.compare(pass, user.pass);

      if (validPassword) {
        // Create a token with user id, email, and any other necessary information
        const token = jwt.sign({ id: user.id, email: user.email }, SECRET_KEY, { expiresIn: '1h' });

        // Correct password, login successful
        res.json({ success: true, message: 'Login successful.', userId: user.id, token }); // Return the token
        console.log("Login successful");
      } else {
        // Incorrect password
        res.status(401).json({ success: false, message: 'Incorrect password.' });
      }
    } else {
      // User not found
      res.status(404).json({ success: false, message: 'User not found.' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Error during login.' });
  }
});

module.exports = app;


