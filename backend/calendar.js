const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('./db');

const router = express.Router();
const SECRET_KEY = 'your_secret_key';

const verifyToken = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1];

    if (!token) {
        return res.status(403).json({ message: 'Access denied. No token provided.' });
    }

    jwt.verify(token, SECRET_KEY, (err, decoded) => {
        if (err) {
            return res.status(401).json({ message: 'Invalid token.' });
        }
        req.userId = decoded.id;
        next();
    });
};

const checkIfDoctor = async (req, res, next) => {
    const userId = req.userId;

    try {
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

/*router.post('/:userId', verifyToken, checkIfDoctor, async (req, res) => {
    const userId = req.params.userId;
    const { availability } = req.body;

    if (!availability || availability.length === 0) {
        return res.status(400).json({ message: 'No availability provided.' });
    }

    await pool.query('BEGIN');

    try {
        // Ottieni le disponibilità esistenti
        const existingAvailabilityResult = await pool.query(
            'SELECT available_date::date, start_time::time, end_time::time FROM availability WHERE user_id = $1',
            [userId]
        );
        const existingAvailability = existingAvailabilityResult.rows;

        for (let entry of availability) {
            const { date, start_time, end_time } = entry;
            
            // Converti le stringhe in oggetti Date per confronti accurati
            const availabilityDate = new Date(date);
            const now = new Date();
            
            // Crea oggetti Date per gli orari di inizio e fine
            const [startHour, startMinute] = start_time.split(':');
            const [endHour, endMinute] = end_time.split(':');
            
            const startDateTime = new Date(availabilityDate);
            startDateTime.setHours(parseInt(startHour), parseInt(startMinute), 0);
            
            const endDateTime = new Date(availabilityDate);
            endDateTime.setHours(parseInt(endHour), parseInt(endMinute), 0);

            // Controlla se la data è nel passato
            if (availabilityDate < new Date(now.toDateString())) {
                await pool.query('ROLLBACK');
                return res.status(400).json({ 
                    message: 'La data deve essere futura.',
                    date: date
                });
            }

            // Se la data è oggi, controlla che l'orario non sia passato
            if (availabilityDate.toDateString() === now.toDateString()) {
                if (startDateTime <= now) {
                    await pool.query('ROLLBACK');
                    return res.status(400).json({ 
                        message: 'L\'orario di inizio deve essere futuro.',
                        date: date,
                        start_time: start_time
                    });
                }
            }

            // Controlla che l'orario di fine sia maggiore di quello di inizio
            if (endDateTime <= startDateTime) {
                await pool.query('ROLLBACK');
                return res.status(400).json({ 
                    message: "L'orario di fine deve essere successivo all'orario di inizio.",
                    date: date,
                    start_time: start_time,
                    end_time: end_time
                });
            }

            // Controllo sovrapposizioni
            const hasOverlap = existingAvailability.some(existing => {
                const existingDate = new Date(existing.available_date);
                
                // Se le date sono diverse, non c'è sovrapposizione
                if (existingDate.toDateString() !== availabilityDate.toDateString()) {
                    return false;
                }

                // Converti gli orari esistenti in oggetti Date per un confronto accurato
                const [existingStartHour, existingStartMinute] = existing.start_time.split(':');
                const [existingEndHour, existingEndMinute] = existing.end_time.split(':');
                
                const existingStartDateTime = new Date(existingDate);
                existingStartDateTime.setHours(parseInt(existingStartHour), parseInt(existingStartMinute), 0);
                
                const existingEndDateTime = new Date(existingDate);
                existingEndDateTime.setHours(parseInt(existingEndHour), parseInt(existingEndMinute), 0);

                // Controlla sovrapposizione
                return (startDateTime < existingEndDateTime && endDateTime > existingStartDateTime);
            });

            if (hasOverlap) {
                await pool.query('ROLLBACK');
                return res.status(400).json({ 
                    message: 'Esiste già una disponibilità salvata in questo slot orario.',
                    date: date,
                    start_time: start_time,
                    end_time: end_time
                });
            }
        }

        // Inserisci le nuove disponibilità
        const insertQuery = 'INSERT INTO availability (user_id, available_date, start_time, end_time) VALUES ($1, $2, $3, $4)';
        for (let entry of availability) {
            const { date, start_time, end_time } = entry;
            await pool.query(insertQuery, [userId, date, start_time, end_time]);
        }

        await pool.query('COMMIT');
        res.status(200).json({ message: 'Availability saved successfully!' });
    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('Error saving availability:', err);
        res.status(500).json({ message: 'Error saving availability.' });
    }
});*/


router.post('/:userId', verifyToken, checkIfDoctor, async (req, res) => {
    const userId = req.params.userId;
    const { availability } = req.body;

    if (!availability || availability.length === 0) {
        return res.status(400).json({ message: 'No availability provided.' });
    }

    // Aggiungi un campo max_patients (ad esempio, 5 pazienti per default)
    const defaultMaxPatients = 5;

    await pool.query('BEGIN');

    try {
        // Ottieni le disponibilità esistenti
        const existingAvailabilityResult = await pool.query(
            'SELECT available_date::date, start_time::time, end_time::time FROM availability WHERE user_id = $1',
            [userId]
        );
        const existingAvailability = existingAvailabilityResult.rows;

        for (let entry of availability) {
            const { date, start_time, end_time, max_patients = defaultMaxPatients } = entry;
            
            // Verifica che max_patients sia un numero positivo
            if (max_patients <= 0 || isNaN(max_patients)) {
                await pool.query('ROLLBACK');
                return res.status(400).json({
                    message: 'Il numero massimo di pazienti deve essere un numero positivo.',
                    date: date,
                    start_time: start_time,
                    end_time: end_time
                });
            }

            // Converti le stringhe in oggetti Date per confronti accurati
            const availabilityDate = new Date(date);
            const now = new Date();
            
            // Crea oggetti Date per gli orari di inizio e fine
            const [startHour, startMinute] = start_time.split(':');
            const [endHour, endMinute] = end_time.split(':');
            
            const startDateTime = new Date(availabilityDate);
            startDateTime.setHours(parseInt(startHour), parseInt(startMinute), 0);
            
            const endDateTime = new Date(availabilityDate);
            endDateTime.setHours(parseInt(endHour), parseInt(endMinute), 0);

            // Controlla se la data è nel passato
            if (availabilityDate < new Date(now.toDateString())) {
                await pool.query('ROLLBACK');
                return res.status(400).json({ 
                    message: 'La data deve essere futura.',
                    date: date
                });
            }

            // Se la data è oggi, controlla che l'orario non sia passato
            if (availabilityDate.toDateString() === now.toDateString()) {
                if (startDateTime <= now) {
                    await pool.query('ROLLBACK');
                    return res.status(400).json({ 
                        message: 'L\'orario di inizio deve essere futuro.',
                        date: date,
                        start_time: start_time
                    });
                }
            }

            // Controlla che l'orario di fine sia maggiore di quello di inizio
            if (endDateTime <= startDateTime) {
                await pool.query('ROLLBACK');
                return res.status(400).json({ 
                    message: "L'orario di fine deve essere successivo all'orario di inizio.",
                    date: date,
                    start_time: start_time,
                    end_time: end_time
                });
            }

            // Controllo sovrapposizioni
            const hasOverlap = existingAvailability.some(existing => {
                const existingDate = new Date(existing.available_date);
                
                // Se le date sono diverse, non c'è sovrapposizione
                if (existingDate.toDateString() !== availabilityDate.toDateString()) {
                    return false;
                }

                // Converti gli orari esistenti in oggetti Date per un confronto accurato
                const [existingStartHour, existingStartMinute] = existing.start_time.split(':');
                const [existingEndHour, existingEndMinute] = existing.end_time.split(':');
                
                const existingStartDateTime = new Date(existingDate);
                existingStartDateTime.setHours(parseInt(existingStartHour), parseInt(existingStartMinute), 0);
                
                const existingEndDateTime = new Date(existingDate);
                existingEndDateTime.setHours(parseInt(existingEndHour), parseInt(existingEndMinute), 0);

                // Controlla sovrapposizione
                return (startDateTime < existingEndDateTime && endDateTime > existingStartDateTime);
            });

            if (hasOverlap) {
                await pool.query('ROLLBACK');
                return res.status(400).json({ 
                    message: 'Esiste già una disponibilità salvata in questo slot orario.',
                    date: date,
                    start_time: start_time,
                    end_time: end_time
                });
            }

            // Inserisci la nuova disponibilità includendo il campo max_patients
            await pool.query(
                'INSERT INTO availability (user_id, available_date, start_time, end_time, max_patients) VALUES ($1, $2, $3, $4, $5)',
                [userId, availabilityDate, startDateTime.toLocaleTimeString('it-IT').slice(0, 5), endDateTime.toLocaleTimeString('it-IT').slice(0, 5), max_patients]
            );
        }

        // Commit delle modifiche
        await pool.query('COMMIT');
        return res.status(200).json({ message: 'Disponibilità salvate con successo.' });

    } catch (error) {
        // In caso di errore, esegui un rollback
        await pool.query('ROLLBACK');
        console.error('Errore durante l\'inserimento delle disponibilità:', error);
        return res.status(500).json({ message: 'Errore durante l\'inserimento delle disponibilità.' });
    }
});



router.get('/:userId', verifyToken, async (req, res) => {
    const userId = req.params.userId;

    try {
        const result = await pool.query('SELECT available_date, start_time, end_time FROM availability WHERE user_id = $1', [userId]);

        if (result.rows.length > 0) {
            const availability = result.rows.map(row => ({
                date: row.available_date,
                start_time: row.start_time,
                end_time: row.end_time
            }));
            res.status(200).json({ availability });
        } else {
            // Invece di restituire un errore, restituisci semplicemente una lista vuota
            res.status(200).json({ availability: [] });
        }
        
    } catch (err) {
        console.error('Error fetching availability:', err);
        res.status(500).json({ message: 'Error fetching availability.' });
    }
});

// Route to delete a specific availability
const { parseISO, format } = require('date-fns');

router.delete('/:userId', verifyToken, checkIfDoctor, async (req, res) => {
    const userId = req.params.userId;
    const { date, start_time, end_time } = req.body;

    // Usa date-fns per evitare conversioni UTC
    const date_formatted = format(parseISO(date), 'yyyy-MM-dd');

    console.log(date_formatted, start_time, end_time, userId);

    try {
        const result = await pool.query(
            `DELETE FROM availability 
             WHERE user_id = $1 AND available_date = $2 AND start_time = $3 AND end_time = $4`,
            [userId, date_formatted, start_time, end_time]
        );

        if (result.rowCount > 0) {
            res.status(200).json({ message: 'Availability deleted successfully.' });
        } else {
            res.status(404).json({ message: 'Availability not found.' });
        }
    } catch (err) {
        console.error('Error deleting availability:', err);
        res.status(500).json({ message: 'Error deleting availability.' });
    }
});


module.exports = router;