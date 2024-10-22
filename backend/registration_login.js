
const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const pool = require('./db');
const bcrypt = require('bcrypt');
const { check, validationResult } = require('express-validator');

const app = express();
const SECRET_KEY = 'your_secret_key';  // Modifica questa chiave segreta per la tua applicazione

// Middleware
app.use(express.json());
app.use(cors());

// Registration (Sign Up)
app.post('/register', [
  check('email').isEmail().withMessage('Invalid email format.'),
  check('pass')
    .isLength({ min: 12 }).withMessage('Password must be at least 12 characters long.')
    .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter.')
    .matches(/[a-z]/).withMessage('Password must contain at least one lowercase letter.')
    .matches(/[0-9]/).withMessage('Password must contain at least one number.')
    .matches(/[^A-Za-z0-9]/).withMessage('Password must contain at least one special character.'),
  check('vat_number')
    .optional()
    .matches(/^[A-Z]{2}\d{11}$/).withMessage('Invalid VAT number format.'),
  check('iban')
    .optional()
    .matches(/^[A-Z]{2}\d{2}[A-Z0-9]{1,30}$/).withMessage('Invalid IBAN format.'),
  check('professional_insurance_expiry_date')
    .optional()
    .isISO8601().withMessage('Invalid expiry date format. Use YYYY-MM-DD.')
], async (req, res) => {
  const {
    email, pass, role, first_name, last_name, birth_date, address, vat_number, professional_insurance_number, iban, professional_association_registration, professional_insurance_expiry_date
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
    if (!first_name || !last_name || !birth_date || !address || !vat_number || !professional_insurance_number || !iban || !professional_association_registration || !professional_insurance_expiry_date) {
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
    // Controlla se l'email esiste già
    const emailCheck = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (emailCheck.rows.length > 0) {
      return res.status(400).json({ success: false, message: 'Email already in use.' });
    }

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
        `INSERT INTO users_type_1 (email, pass, first_name, last_name, birth_date, address, vat_number, professional_insurance_number, professional_insurance_expiry_date, iban, professional_association_registration)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id`,
        [email, hashedPassword, first_name, last_name, birth_date, address, vat_number, professional_insurance_number, professional_insurance_expiry_date, iban, professional_association_registration]
      );
    }

    // Send success response with the user ID
    res.json({ success: true, message: 'User registered successfully.', userId: result.rows[0].id });
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

module.exports = app;









