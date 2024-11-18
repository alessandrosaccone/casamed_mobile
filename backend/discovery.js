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
  const { doctorId, patientId, bookingDate, startTime, endTime, symptomDescription} = req.body;
  try {
    if (!doctorId || !patientId || !bookingDate || !startTime || !endTime || !symptomDescription) {
      return res.status(400).json({ success: false, message: 'Dati mancanti per la prenotazione.' });
    }

    // Inserimento della prenotazione nel database
    const result = await pool.query(`
      INSERT INTO bookings (doctor_id, patient_id, booking_date, start_time, end_time, symptom_description)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *;
    `, [doctorId, patientId, bookingDate, startTime, endTime, symptomDescription]);

    const date = new Date(bookingDate);

    // Estrai solo la parte della data (anno-mese-giorno)
    const formattedDate = date.toISOString().split('T')[0]; // '2024-11-27'

    console.log(formattedDate);

    // Decremento del contatore max_patients nella tabella availability
    /*const updateAvailability = await pool.query(`
      UPDATE availability
      SET max_patients = max_patients - 1
      WHERE user_id = $1
      AND available_date = $2
      AND start_time = $3
      AND end_time = $4
      AND max_patients > 0; -- Evita decrementi sotto lo zero
    `, [doctorId, formattedDate, startTime, endTime]);

    if (updateAvailability.rowCount === 0) {
      return res.status(400).json({
        success: false,
        message: 'Non è stato possibile aggiornare la disponibilità. Potrebbe essere esaurita o non trovata.'
      });
    }*/

    // Rimozione della disponibilità se max_patients è pari a 0
    const deleteAvailability = await pool.query(`
      DELETE FROM availability
      WHERE user_id = $1
      AND available_date = $2
      AND start_time = $3
      AND end_time = $4
      AND max_patients = 0;
    `, [doctorId, formattedDate, startTime, endTime]);

    if (deleteAvailability.rowCount > 0) {
      console.log('Disponibilità eliminata con successo');
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



// Endpoint per la richiesta di disponibilità urgenti
router.get('/urgentbookings', authenticateToken, async (req, res) => {
  try {
    // Scriviamo la query SQL per selezionare i medici con disponibilità future
    const query = ` 
      SELECT u.id, u.first_name, u.last_name, a.available_date, a.start_time, a.end_time
      FROM users_type_1 u
      JOIN availability a ON u.id = a.user_id
      WHERE a.available_date > NOW() -- Solo le disponibilità future
      ORDER BY a.available_date ASC, a.start_time ASC -- Ordina dalla disponibilità più recente
      LIMIT 1; -- Restituisce solo la disponibilità più vicina
    `;
    
    // Eseguiamo la query
    const result = await pool.query(query);

    // Controlliamo se sono stati trovati risultati
    if (result.rows.length > 0) {
      // Formattiamo la data e l'ora
      const formattedResult = result.rows.map(row => ({
        id: row.id,
        first_name: row.first_name,
        last_name: row.last_name,
        available_date: new Date(row.available_date).toISOString().split('T')[0], // Formato 'YYYY-MM-DD'
        start_time: row.start_time.slice(0, 5),
        end_time: row.end_time.slice(0, 5)
      }));

      // Log del risultato formattato
      console.log('Risultato formattato:', formattedResult);

      // Ritorniamo la disponibilità più recente come array di oggetti, simile a '/discovery'
      res.json({ success: true, urgentBookings: formattedResult });
    } else {
      // Se non ci sono disponibilità future, inviamo un array vuoto
      res.json({ success: true, urgentBookings: [] });
    }
  } catch (error) {
    console.error('Errore nella richiesta delle disponibilità urgenti:', error);
    res.status(500).json({ success: false, message: 'Errore interno del server' });
  }
});






module.exports = router;
