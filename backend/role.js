const express = require('express');
const pool = require('./db'); // Assicurati di avere la connessione al database
const jwt = require('jsonwebtoken');
const router = express.Router();

const SECRET_KEY = 'your_secret_key'; /*SECURITY LEAK*/

// Middleware per autenticare il token
const authenticateToken = (req, res, next) => {
    const token = req.headers['authorization'] && req.headers['authorization'].split(' ')[1];
    if (!token) return res.sendStatus(401); // Unauthorized

    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) return res.sendStatus(403); // Forbidden
        req.user = user;
        next();
    });
};

// Endpoint per controllare se un utente è un medico
router.get('/user/:userId/role', authenticateToken, async (req, res) => {
    const userId = req.params.userId;

    try {
        const result = await pool.query('SELECT CASE WHEN EXISTS (SELECT 1 FROM users WHERE id = $1 AND (role = 1 OR role = 2)) THEN TRUE ELSE FALSE END AS isDoctor', [userId]);

        if (result.rows.length > 0) {
            res.status(200).json({ isDoctor: result.rows[0].isdoctor });
        } else {
            res.status(404).json({ message: 'User not found.' });
        }
    } catch (error) {
        console.error('Error checking user role:', error);
        res.status(500).json({ message: 'Error checking user role.' });
    }
});

module.exports = router; // Esporta il router