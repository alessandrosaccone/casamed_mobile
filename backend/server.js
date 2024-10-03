const express = require('express');
const cors = require('cors');
const pool = require('./db'); // Importa la connessione al database dal file db.js
const bcrypt = require('bcrypt'); // Per gestire la crittografia delle password
const app = express();
const port = 3000;

// Middleware
app.use(express.json());
app.use(cors());

// Registrazione (Sign Up)
app.post('/register', async (req, res) => {
  const { email, pass, role, first_name, last_name, birth_date, other_field_1, other_field_2 } = req.body;

  // Verifica che email e pass siano presenti
  if (!email || !pass) {
    return res.status(400).json({ success: false, message: 'Email e password sono obbligatorie.' });
  }

  if (role === 0) {
    // Se il ruolo è 0, controlla i campi specifici per il ruolo 0
    if (!first_name || !last_name || !birth_date) {
      return res.status(400).json({ success: false, message: 'Nome, cognome e data di nascita sono obbligatori per il ruolo 0.' });
    }
  } else if (role === 1) {
    // Se il ruolo è 1, controlla i campi specifici per il ruolo 1
    if (!first_name || !last_name || !birth_date || !other_field_1 || !other_field_2) {
      return res.status(400).json({ success: false, message: 'I campi specifici sono obbligatori per il ruolo 1.' });
    }
  } else {
    return res.status(400).json({ success: false, message: 'Ruolo non valido.' });
  }

  try {
    // Crittografa la password prima di salvarla
    const hashedPassword = await bcrypt.hash(pass, 10);

    let result;

    if (role === 0) {
      // Inserisci i dati per l'utente di tipo 0
      result = await pool.query(
        'INSERT INTO users_type_0 (email, pass, first_name, last_name, birth_date) VALUES ($1, $2, $3, $4, $5) RETURNING id',
        [email, hashedPassword, first_name, last_name, birth_date]
      );
    } else if (role === 1) {
      // Inserisci i dati per l'utente di tipo 1
      result = await pool.query(
        'INSERT INTO users_type_1 (email, pass,first_name, last_name, birth_date, other_field_1, other_field_2) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
        [email, hashedPassword, first_name, last_name, birth_date, other_field_1, other_field_2]
      );
    }

    // Invia risposta di successo con l'id dell'utente appena registrato
    res.json({ success: true, message: 'Utente registrato con successo.', userId: result.rows[0].id });
    console.log("Utente registrato con successo")
  } catch (err) {
    console.error('Errore dettagliato:', err);
    res.status(500).json({ success: false, message: 'Errore durante la registrazione.' });
  }
});




// Login (Sign In)
app.post('/login', async (req, res) => {
  const { email, pass } = req.body;

  try {
    // Cerca l'utente per email
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (result.rows.length > 0) {
      const user = result.rows[0];

      // Confronta la password inserita con quella crittografata nel DB
      const validPassword = await bcrypt.compare(pass, user.pass);

      if (validPassword) {
        // Password corretta, login riuscito
        res.json({ success: true, message: 'Login effettuato con successo.', userId: user.id });
        console.log("Login effettuato con successo")
      } else {
        // Password non corretta
        res.status(401).json({ success: false, message: 'Password errata.' });
      }
    } else {
      // Utente non trovato
      res.status(404).json({ success: false, message: 'Utente non trovato.' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Errore durante il login.' });
  }
});

// Avvia il server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
