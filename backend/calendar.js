/*const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('./db'); // Importa la configurazione del database

const router = express.Router();
const SECRET_KEY = 'your_secret_key'; // Assicurati di utilizzare lo stesso segreto usato per firmare il token

// Middleware per verificare il token
const verifyToken = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1]; // Supponendo che il token sia nel formato "Bearer TOKEN"

    if (!token) {
        return res.status(403).json({ message: 'Access denied. No token provided.' });
    }

    jwt.verify(token, SECRET_KEY, (err, decoded) => {
        if (err) {
            return res.status(401).json({ message: 'Invalid token.' });
        }
        req.userId = decoded.id; // Salva l'ID dell'utente nel request object
        next();
    });
};

// Middleware per verificare se l'utente è un medico
const checkIfDoctor = async (req, res, next) => {
    const userId = req.userId; // Ottieni l'ID dell'utente dal token

    try {
        // Controlla se l'utente appartiene alla tabella users_type_1 (medico)
        const result = await pool.query('SELECT id FROM users_type_1 WHERE id = $1', [userId]);

        if (result.rows.length === 0) {
            return res.status(403).json({ message: 'Access denied. Only doctors can access this resource.' });
        }
        next();
    } catch (err) {
        console.error('Error checking user role:', err);
        return res.status(500).json({ message: 'Error verifying user role.' });
    }
};

// Endpoint per salvare disponibilità
router.post('/:userId', verifyToken, checkIfDoctor, async (req, res) => {
    const userId = req.params.userId;
    const { availability } = req.body; // Un array di date

    if (!availability || availability.length === 0) {
        return res.status(400).json({ message: 'No availability provided.' });
    }

    try {
        // Inizia una transazione
        await pool.query('BEGIN');

        // Elimina le vecchie disponibilità
        await pool.query('DELETE FROM availability WHERE user_id = $1', [userId]);

        // Inserisci le nuove disponibilità
        const query = 'INSERT INTO availability (user_id, available_date) VALUES ($1, $2)';
        for (let date of availability) {
            await pool.query(query, [userId, date]);
        }

        // Completa la transazione
        await pool.query('COMMIT');

        res.status(200).json({ message: 'Availability saved successfully!' });
    } catch (err) {
        // In caso di errore, annulla la transazione
        await pool.query('ROLLBACK');
        console.error('Error saving availability:', err);
        res.status(500).json({ message: 'Error saving availability.' });
    }
});

// Endpoint per recuperare le disponibilità
router.get('/:userId', verifyToken, checkIfDoctor, async (req, res) => {
    const userId = req.params.userId;

    try {
        // Recupera le disponibilità dal database
        const result = await pool.query('SELECT available_date FROM availability WHERE user_id = $1', [userId]);

        if (result.rows.length > 0) {
            const availability = result.rows.map(row => row.available_date);
            res.status(200).json({ availability });
        } else {
            res.status(404).json({ message: 'No availability found for this user.' });
        }
    } catch (err) {
        console.error('Error fetching availability:', err);
        res.status(500).json({ message: 'Error fetching availability.' });
    }
});

module.exports = router;*/

const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('./db'); // Importa la configurazione del database

const router = express.Router();
const SECRET_KEY = 'your_secret_key'; // Assicurati di utilizzare lo stesso segreto usato per firmare il token

// Middleware per verificare il token
const verifyToken = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1]; // Supponendo che il token sia nel formato "Bearer TOKEN"

    if (!token) {
        return res.status(403).json({ message: 'Access denied. No token provided.' });
    }

    jwt.verify(token, SECRET_KEY, (err, decoded) => {
        if (err) {
            return res.status(401).json({ message: 'Invalid token.' });
        }
        req.userId = decoded.id; // Salva l'ID dell'utente nel request object
        next();
    });
};

// Middleware per verificare se l'utente è un medico
const checkIfDoctor = async (req, res, next) => {
    const userId = req.userId; // Ottieni l'ID dell'utente dal token

    try {
        // Controlla se l'utente appartiene alla tabella users_type_1 (medico)
        const result = await pool.query('SELECT id FROM users_type_1 WHERE id = $1', [userId]);

        if (result.rows.length === 0) {
            return res.status(403).json({ message: 'Access denied. Only doctors can access this resource.' });
        }
        next();
    } catch (err) {
        console.error('Error checking user role:', err);
        return res.status(500).json({ message: 'Error verifying user role.' });
    }
};

// Endpoint per salvare disponibilità (data, orario di inizio e orario di fine)
router.post('/:userId', verifyToken, checkIfDoctor, async (req, res) => {
    const userId = req.params.userId;
    const { availability } = req.body; // Un array di oggetti { date, start_time, end_time }

    if (!availability || availability.length === 0) {
        return res.status(400).json({ message: 'No availability provided.' });
    }

    try {
        // Inizia una transazione
        await pool.query('BEGIN');

        // Elimina le vecchie disponibilità
        await pool.query('DELETE FROM availability WHERE user_id = $1', [userId]);

        // Inserisci le nuove disponibilità
        const query = 'INSERT INTO availability (user_id, available_date, start_time, end_time) VALUES ($1, $2, $3, $4)';
        for (let entry of availability) {
            const { date, start_time, end_time } = entry;
            await pool.query(query, [userId, date, start_time, end_time]);
        }

        // Completa la transazione
        await pool.query('COMMIT');

        res.status(200).json({ message: 'Availability saved successfully!' });
    } catch (err) {
        // In caso di errore, annulla la transazione
        await pool.query('ROLLBACK');
        console.error('Error saving availability:', err);
        res.status(500).json({ message: 'Error saving availability.' });
    }
});

// Endpoint per recuperare le disponibilità (data, orario di inizio e orario di fine)
router.get('/:userId', verifyToken, checkIfDoctor, async (req, res) => {
    const userId = req.params.userId;

    try {
        // Recupera le disponibilità dal database
        const result = await pool.query('SELECT available_date, start_time, end_time FROM availability WHERE user_id = $1', [userId]);

        if (result.rows.length > 0) {
            const availability = result.rows.map(row => ({
                date: row.available_date,
                start_time: row.start_time,
                end_time: row.end_time
            }));
            res.status(200).json({ availability });
        } else {
            res.status(404).json({ message: 'No availability found for this user.' });
        }
    } catch (err) {
        console.error('Error fetching availability:', err);
        res.status(500).json({ message: 'Error fetching availability.' });
    }
});

module.exports = router;

