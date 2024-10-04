const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const pool = require('./db'); // Import the database connection from db.js
const bcrypt = require('bcrypt'); // For password hashing
const app = express();

const SECRET_KEY = 'your_secret_key'; /*SECURITY LEAK*/

// Registration (Sign Up)
app.post('/register', async (req, res) => {
  const {
    email, pass, role, first_name, last_name, birth_date, address, vat_number, professional_insurance_number, iban, professional_association_registration
  } = req.body;

  // Verify that email and password are provided
  if (!email || !pass) {
    return res.status(400).json({ success: false, message: 'Email and password are required.' });
  }

  if (role === 0) {
    // If role is 0, check the specific fields for role 0
    if (!first_name || !last_name || !birth_date) {
      return res.status(400).json({ success: false, message: 'First name, last name, and birth date are required for role 0.' });
    }
  } else if (role === 1) {
    // If role is 1, check the specific fields for role 1
    if (!first_name || !last_name || !birth_date || !address || !vat_number || !professional_insurance_number || !iban || !professional_association_registration) {
      return res.status(400).json({ success: false, message: 'All fields are required for role 1 (professional).' });
    }
  } else {
    return res.status(400).json({ success: false, message: 'Invalid role.' });
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