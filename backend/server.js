// server.js
const express = require('express');
const cors = require('cors');
const pool = require('./db'); // Assicurati di importare la connessione al database
const bcrypt = require('bcrypt');
const app = express();
const port = 3000;

// Importa le route
const registrationLoginRoutes = require('./registration_login');
const profileRoutes = require('./profile'); // Importa le route del profilo
const calendarRoutes = require('./calendar'); // Importa le route del calendario
const roleRoutes = require('./role'); // Importa le route per il controllo del ruolo
const discoveryRoutes = require('./discovery');
const paymentsRoutes = require('./payment'); // adatta il path se serve



// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // Supporto per dati URL-encoded
app.use(cors());

// Usa le route
app.use('/', registrationLoginRoutes);  // Route per login/registrazione
app.use('/profile', profileRoutes);     // Route per il profilo
app.use('/calendar', calendarRoutes);   // Route per il calendario
app.use('/', roleRoutes); // Usa le route per il controllo del ruolo
app.use('/', discoveryRoutes);
app.use('/payments', paymentsRoutes);


// Avvia il server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
