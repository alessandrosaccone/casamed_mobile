const express = require('express');
const cors = require('cors');
const { check, validationResult } = require('express-validator'); // Importa le funzioni di express-validator
const axios = require('axios'); // Import axios for API requests
const app = express();
const port = 3000;

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
app.use('/', roleRoutes); // Usa le route


// Avvia il server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
