const express = require('express');
const pool = require('./db'); // Connessione al database
const router = express.Router();
const authenticateToken = require('./authMiddleware'); // Middleware di autenticazione

// Endpoint protetto per ottenere i medici
router.get('/discovery', authenticateToken, async (req, res) => {
  try {
    // Recupera ID, nome e cognome dei medici
    const result = await pool.query(`
      SELECT id, first_name, last_name 
      FROM users_type_1
    `);

    res.json({ success: true, doctors: result.rows });
  } catch (err) {
    console.error('Errore durante il recupero dei dati:', err);
    res.status(500).json({ success: false, message: 'Errore durante il recupero dei dati.' });
  }
});

// Endpoint protetto per creare una prenotazione
router.put('/bookings', authenticateToken, async (req, res) => {
  const { doctorId, patientId, bookingDate, startTime, endTime } = req.body;

  try {
    // Validazione dei dati di input
    if (!doctorId || !patientId || !bookingDate || !startTime || !endTime) {
      return res.status(400).json({ success: false, message: 'Dati mancanti per la prenotazione.' });
    }

    // Inserimento della prenotazione nel database
    const result = await pool.query(`
      INSERT INTO bookings (doctor_id, patient_id, booking_date, start_time, end_time)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
    `, [doctorId, patientId, bookingDate, startTime, endTime]);

    // Risposta con i dettagli della prenotazione
    res.json({ success: true, booking: result.rows[0] });
  } catch (err) {
    console.error('Errore durante la creazione della prenotazione:', err);
    
    // Risposta d'errore dettagliata
    if (err.code === '23505') { // Codice errore per violazione di unicità
      res.status(409).json({ success: false, message: 'La prenotazione esiste già per questo orario.' });
    } else {
      res.status(500).json({ success: false, message: 'Errore durante la creazione della prenotazione.' });
    }
  }
});

module.exports = router;
