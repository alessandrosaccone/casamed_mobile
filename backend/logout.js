// logout.js
const express = require('express');
const authenticateToken = require('./authMiddleware');

const app = express();

/**
 * LOGOUT SEMPLICE
 * Non invalida il token lato server, solo conferma l'operazione
 * Il frontend dovrà rimuovere il token dal dispositivo
 */
app.post('/logout', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const userEmail = req.user.email;
        
        // Log dell'operazione (opzionale)
        console.log(`User ${userId} (${userEmail}) logged out at ${new Date().toISOString()}`);
        
        
        res.json({
            success: true,
            message: 'Logout effettuato con successo'
        });
        
    } catch (error) {
        console.error('Errore durante logout:', error);
        res.status(500).json({
            success: false,
            message: 'Errore interno del server durante il logout'
        });
    }
});

/**
 * VERIFICA STATO TOKEN
 * Controlla se il token corrente è ancora valido (non so ancora se ci servirà)
 */
app.get('/verify-token', authenticateToken, (req, res) => {
    // Se arriviamo qui, il token è valido (ha passato authenticateToken)
    res.json({
        success: true,
        message: 'Token valido',
        user: {
            id: req.user.id,
            email: req.user.email
        },
        tokenExpires: new Date(req.user.exp * 1000)
    });
});

module.exports = app;