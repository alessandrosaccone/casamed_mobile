const express = require('express');
const pool = require('./db'); // Connessione al database
const router = express.Router();
const authenticateToken = require('./authMiddleware'); // Middleware di autenticazione

// Endpoint protetto per ottenere i medici
router.get('/discovery', authenticateToken, async (req, res) => {
  try {
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

router.put('/bookings', authenticateToken, async (req, res) => {
  const { doctorId, patientId, bookingDate, startTime, endTime } = req.body;
  try {
    if (!doctorId || !patientId || !bookingDate || !startTime || !endTime) {
      return res.status(400).json({ success: false, message: 'Dati mancanti per la prenotazione.' });
    }

    // Inserimento della prenotazione nel database
    const result = await pool.query(`
      INSERT INTO bookings (doctor_id, patient_id, booking_date, start_time, end_time)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
    `, [doctorId, patientId, bookingDate, startTime, endTime]);

    const date = new Date(bookingDate);

    // Estrai solo la parte della data (anno-mese-giorno)
    const formattedDate = date.toISOString().split('T')[0]; // '2024-11-27'

    console.log(formattedDate);

    // Rimozione della disponibilità corrispondente nella tabella availability
    const deleteAvailability = await pool.query(`
      DELETE FROM availability
      WHERE user_id = $1
      AND available_date = $2
      AND start_time = $3
      AND end_time = $4;
    `, [doctorId, formattedDate, startTime, endTime]);


    if (deleteAvailability.rowCount === 0) {
      console.warn('Disponibilità eliminata con successo');
    }

    res.json({ success: true, booking: result.rows[0] });
  } catch (err) {
    console.error('Errore durante la creazione della prenotazione:', err);

    if (err.code === '23505') { // Violazione di unicità
      res.status(409).json({ success: false, message: 'La prenotazione esiste già per questo orario.' });
    } else {
      res.status(500).json({ success: false, message: 'Errore durante la creazione della prenotazione.' });
    }
  }
});

module.exports = router;
