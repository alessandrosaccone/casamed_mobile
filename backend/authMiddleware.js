const jwt = require('jsonwebtoken');
const SECRET_KEY = 'your_secret_key';  // Usa la stessa chiave segreta che hai usato per firmare il token

// Middleware per verificare il token JWT
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Il token JWT viene di solito inviato come 'Bearer <token>'

  if (!token) {
    return res.status(401).json({ success: false, message: 'Accesso negato. Nessun token fornito.' });
  }

  // Verifica il token
  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Token non valido o scaduto.' });
    }
    
    // Il token è valido, aggiungi i dati dell'utente alla richiesta
    req.user = user;
    req.token = token; // ← AGGIUNGI QUESTA RIGA
    next();  // Passa al prossimo middleware o alla route handler
  });
}

module.exports = authenticateToken;
