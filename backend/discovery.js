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

/*router.put('/bookings', authenticateToken, async (req, res) => {
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
});*/


router.put('/bookings', authenticateToken, async (req, res) => {
  const { doctorId, patientId, bookingDate, startTime, endTime, symptomDescription } = req.body;

  try {
    // Verifica che tutti i campi necessari siano presenti
    if (!doctorId || !patientId || !bookingDate || !startTime || !endTime || !symptomDescription) {
      return res.status(400).json({ success: false, message: 'Dati mancanti per la prenotazione.' });
    }

    // Inserimento della prenotazione nel database
    const result = await pool.query(`
      INSERT INTO bookings (doctor_id, patient_id, booking_date, start_time, end_time, symptom_description)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *;
    `, [doctorId, patientId, bookingDate, startTime, endTime, symptomDescription]);

    // Converte la data per estrarre solo la parte della data (anno-mese-giorno)
    const date = new Date(bookingDate);
    const formattedDate = date.toISOString().split('T')[0]; // '2024-11-27'

    console.log(formattedDate);

    // Decremento del campo max_patients nella tabella availability
    const updateAvailability = await pool.query(`
      UPDATE availability
      SET max_patients = max_patients - 1
      WHERE user_id = $1
      AND available_date = $2
      AND start_time = $3
      AND end_time = $4
      AND max_patients > 0
      RETURNING *;
    `, [doctorId, formattedDate, startTime, endTime]);


    if (updateAvailability.rowCount > 0) {
      console.log('Disponibilità aggiornata con successo.');
    } else {
      console.log('Nessuna disponibilità trovata da aggiornare o max_patients già a 0.');
    }

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

    // Risposta con successo e la prenotazione creata
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



// Endpoint per ottenere tutte le prenotazioni di un medico
router.get('/doctor/bookings', authenticateToken, async (req, res) => {
  try {
    // Ottieni l'ID del medico dall'utente autenticato
    const doctorId = req.user.id;

    // Verifica che l'utente sia un medico
    const doctorCheck = await pool.query(`
      SELECT 1 FROM users_type_1 WHERE id = $1;
    `, [doctorId]);

    if (doctorCheck.rowCount === 0) {
      return res.status(403).json({ success: false, message: 'Accesso negato. Utente non autorizzato.' });
    }

    // Recupera le prenotazioni ordinate per ID (decrescente)
    const result = await pool.query(`
      SELECT 
        b.id AS booking_id,
        u.first_name AS patient_first_name,
        u.last_name AS patient_last_name,
        b.booking_date,
        b.start_time,
        b.end_time,
        b.symptom_description,
        b.accepted_booking
      FROM bookings b
      JOIN users_type_0 u ON b.patient_id = u.id
      WHERE b.doctor_id = $1
      ORDER BY b.id ASC; -- Ordinamento basato sull'ID in ordine crescente
    `, [doctorId]);

    // Formatta i risultati
    const formattedBookings = result.rows.map(row => ({
      bookingId: row.booking_id,
      patientFirstName: row.patient_first_name,
      patientLastName: row.patient_last_name,
      bookingDate: new Date(row.booking_date).toISOString().split('T')[0], // yyyy-mm-dd
      startTime: row.start_time.slice(0, 5), // HH:MM
      endTime: row.end_time.slice(0, 5),
      symptomDescription: row.symptom_description,
      acceptedBooking: row.accepted_booking
    }));

    // Restituisci i risultati
    res.json({ success: true, bookings: formattedBookings });
  } catch (err) {
    console.error('Errore durante il recupero delle prenotazioni:', err);
    res.status(500).json({ success: false, message: 'Errore durante il recupero delle prenotazioni.' });
  }
});

// Endpoint per ottenere tutte le prenotazioni di un paziente
router.get('/patient/bookings', authenticateToken, async (req, res) => {
  try {
    // Ottieni l'ID del paziente dall'utente autenticato
    const patientId = req.user.id;

    // Verifica che l'utente sia un paziente
    const patientCheck = await pool.query(`
      SELECT 1 FROM users_type_0 WHERE id = $1;
    `, [patientId]);

    if (patientCheck.rowCount === 0) {
      return res.status(403).json({ success: false, message: 'Accesso negato. Utente non autorizzato.' });
    }

    // Recupera le prenotazioni del paziente ordinate per ID (decrescente)
    const result = await pool.query(`
      SELECT 
        b.id AS booking_id,
        u.first_name AS doctor_first_name,
        u.last_name AS doctor_last_name,
        b.booking_date,
        b.start_time,
        b.end_time,
        b.symptom_description,
        b.accepted_booking
      FROM bookings b
      JOIN users_type_1 u ON b.doctor_id = u.id
      WHERE b.patient_id = $1
      ORDER BY b.id ASC; -- Ordinamento basato sull'ID in ordine decrescente
    `, [patientId]);

    // Formatta i risultati
    const formattedBookings = result.rows.map(row => ({
      bookingId: row.booking_id,
      doctorFirstName: row.doctor_first_name,
      doctorLastName: row.doctor_last_name,
      bookingDate: new Date(row.booking_date).toISOString().split('T')[0], // yyyy-mm-dd
      startTime: row.start_time.slice(0, 5), // HH:MM
      endTime: row.end_time.slice(0, 5),
      symptomDescription: row.symptom_description,
      acceptedBooking: row.accepted_booking
    }));

    // Restituisci i risultati
    res.json({ success: true, bookings: formattedBookings });
  } catch (err) {
    console.error('Errore durante il recupero delle prenotazioni del paziente:', err);
    res.status(500).json({ success: false, message: 'Errore durante il recupero delle prenotazioni.' });
  }
});



// Endpoint per accettare una prenotazione
router.put('/bookings/accept/:id', async (req, res) => {
  const bookingId = req.params.id; // ID della prenotazione da accettare
  const { note } = req.body;      // Nota con l'orario scelto dal medico

  try {
      // Recupera la prenotazione e controlla l'esistenza
      const result = await pool.query(
          'SELECT accepted_booking FROM bookings WHERE id = $1',
          [bookingId]
      );

      if (result.rows.length === 0) {
          return res.status(404).json({ error: 'Prenotazione non trovata.' });
      }

      // Controlla se la prenotazione è già stata accettata
      if (result.rows[0].accepted_booking) {
          return res.status(400).json({ error: 'La prenotazione è già stata accettata.' });
      }

      // Aggiorna la prenotazione con `accepted_booking` e `note`
      await pool.query(
          `UPDATE bookings 
           SET accepted_booking = true, note = $1 
           WHERE id = $2`,
          [note, bookingId]
      );

      res.status(200).json({ message: 'Prenotazione accettata con successo.' });
  } catch (error) {
      console.error('Errore nell\'accettazione della prenotazione:', error);
      res.status(500).json({ error: 'Errore del server.' });
  }
});



module.exports = router;
