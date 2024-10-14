const express = require('express');
const cors = require('cors');
const { check, validationResult } = require('express-validator'); // Importa le funzioni di express-validator
const axios = require('axios'); // Import axios for API requests
const app = express();
const port = 3000;
// Import the registration and login routes from registration_login.js
const registrationLoginRoutes = require('./registration_login');

// Use the routes
// Middleware
app.use(express.json());
app.use(cors());
app.use('/', registrationLoginRoutes);  // Now the routes from registration_login.js will be available in your app

// Start the server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});