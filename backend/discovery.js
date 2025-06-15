const express = require('express');
const pool = require('./db'); // Connessione al database
const router = express.Router();
const authenticateToken = require('./authMiddleware'); // Middleware di autenticazione
const Stripe = require('stripe');
const stripe = Stripe('sk_test_51RBewF4IOwwF31fGuJtENyMlKdSCwh6bmWzllqTz9iKuOev3T2jf8ectenKaxOhafDZVBF3pX9Y7Fd7OH2Fh2dUU00fFvvXvmL');
const { createNotification } = require('./notifications');

// Endpoint protetto per ottenere i medici da users_type_1
router.get('/discovery', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, first_name, last_name, role 
      FROM users
      WHERE (role = 1 OR role = 2)
    `);
    res.json({ success: true, doctors: result.rows });
  } catch (err) {
    console.error('Errore durante il recupero dei dati:', err);
    res.status(500).json({ success: false, message: 'Errore durante il recupero dei dati.' });
  }
});

// Endpoint per ottenere i medici da users con ruolo 2
router.get('/discovery/doctor', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, first_name, last_name 
      FROM users
      WHERE role = 2
    `);
    res.json({ success: true, doctors: result.rows });
  } catch (err) {
    console.error('Errore durante il recupero dei dati:', err);
    res.status(500).json({ success: false, message: 'Errore durante il recupero dei dati.' });
  }
});

// Endpoint per ottenere gli infermieri da users con ruolo 1
router.get('/discovery/nurse', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, first_name, last_name 
      FROM users
      WHERE role = 1
    `);
    res.json({ success: true, nurses: result.rows });
  } catch (err) {
    console.error('Errore durante il recupero dei dati:', err);
    res.status(500).json({ success: false, message: 'Errore durante il recupero dei dati.' });
  }
});

// Endpoint per verificare la disponibilità prima del pagamento
router.put('/bookings/verify', authenticateToken, async (req, res) => {
  const { doctorId, patientId, bookingDate, startTime, endTime, symptomDescription, treatment } = req.body;

  try {
    if (!doctorId || !patientId || !bookingDate || !startTime || !endTime || !symptomDescription || !treatment) {
      return res.status(400).json({ success: false, message: 'Dati mancanti per la prenotazione.' });
    }

    // Controllo se esiste già una prenotazione con gli stessi dettagli
    const existingBooking = await pool.query(`
      SELECT 1 FROM bookings 
      WHERE doctor_id = $1 AND patient_id = $2 AND booking_date = $3 
      AND start_time = $4 AND end_time = $5;
    `, [doctorId, patientId, bookingDate, startTime, endTime]);

    if (existingBooking.rowCount > 0) {
      return res.status(409).json({ success: false, message: 'La prenotazione esiste già per questo orario.' });
    }

    const date = (() => {
      const d = new Date(bookingDate);
      // Usa il fuso orario locale invece di UTC
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    })();

    // Verifica solo la disponibilità senza modificare
    const checkAvailability = await pool.query(`
      SELECT * FROM availability
      WHERE user_id = $1 AND available_date = $2 
      AND start_time = $3 AND end_time = $4 AND max_patients > 0;
    `, [doctorId, date, startTime, endTime]);

    if (checkAvailability.rowCount === 0) {
      return res.status(400).json({ success: false, message: "Disponibilità non trovata o esaurita." });
    }

    res.json({ success: true, message: 'Disponibilità verificata con successo.' });
  } catch (err) {
    console.error('Errore durante la verifica:', err);
    res.status(500).json({ success: false, message: 'Errore durante la verifica della disponibilità.' });
  }
});

// Endpoint per creare la prenotazione dopo pagamento confermato (transazione atomica)
router.post('/bookings/complete', authenticateToken, async (req, res) => {
  const { doctorId, patientId, bookingDate, startTime, endTime, symptomDescription, treatment } = req.body;
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // Controllo finale disponibilità dentro la transazione
    const date = new Date(bookingDate).toISOString().split('T')[0];
    
    const finalAvailabilityCheck = await client.query(`
      SELECT * FROM availability
      WHERE user_id = $1 AND available_date = $2 
      AND start_time = $3 AND end_time = $4 AND max_patients > 0
      FOR UPDATE;
    `, [doctorId, date, startTime, endTime]);

    if (finalAvailabilityCheck.rowCount === 0) {
      throw new Error('Disponibilità non più presente o esaurita.');
    }

    // Controllo finale duplicati dentro la transazione
    const finalDuplicateCheck = await client.query(`
      SELECT 1 FROM bookings 
      WHERE doctor_id = $1 AND patient_id = $2 AND booking_date = $3 
      AND start_time = $4 AND end_time = $5;
    `, [doctorId, patientId, bookingDate, startTime, endTime]);

    if (finalDuplicateCheck.rowCount > 0) {
      throw new Error('La prenotazione esiste già per questo orario.');
    }

    // Inserimento della prenotazione
    const bookingResult = await client.query(`
      INSERT INTO bookings (doctor_id, patient_id, booking_date, start_time, end_time, symptom_description, treatment)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `, [doctorId, patientId, bookingDate, startTime, endTime, symptomDescription, treatment]);

    // Aggiornamento della disponibilità del medico
    const updateAvailability = await client.query(`
      UPDATE availability
      SET max_patients = max_patients - 1
      WHERE user_id = $1 AND available_date = $2 
      AND start_time = $3 AND end_time = $4 AND max_patients > 0
      RETURNING *;
    `, [doctorId, date, startTime, endTime]);

    if (updateAvailability.rowCount === 0) {
      throw new Error("Errore nell'aggiornamento della disponibilità.");
    }

    // Eliminazione della disponibilità se max_patients = 0
    await client.query(`
      DELETE FROM availability
      WHERE user_id = $1 AND available_date = $2 
      AND start_time = $3 AND end_time = $4 AND max_patients = 0;
    `, [doctorId, date, startTime, endTime]);

    // Creazione notifica per il medico
    try {
      // Get doctor and patient details for notification  
      const detailsQuery = await client.query(`
        SELECT 
          d.first_name as doctor_first_name,
          d.last_name as doctor_last_name,
          p.first_name as patient_first_name,
          p.last_name as patient_last_name
        FROM users d, users p
        WHERE d.id = $1 AND p.id = $2
      `, [doctorId, patientId]);

      if (detailsQuery.rowCount > 0) {
        const details = detailsQuery.rows[0];
        
        // Create notification for doctor about new booking
        const notificationMessage = `Nuova prenotazione da ${details.patient_first_name} ${details.patient_last_name} per il ${new Date(bookingDate).toLocaleDateString('it-IT')} alle ${startTime.slice(0, 5)}-${endTime.slice(0, 5)}.`;
        
        await createNotification(
          doctorId,
          'new_booking', 
          'Nuova Prenotazione',
          notificationMessage,
          client
        );
        
        console.log(`Notifica inviata al medico ID: ${doctorId}`);
      }
    } catch (notificationError) {
      console.error('Errore nell\'invio della notifica al medico:', notificationError);
      // Non fallire la prenotazione se la notifica fallisce
    }

    await client.query('COMMIT');
    res.json({ success: true, booking: bookingResult.rows[0] });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Errore durante la creazione della prenotazione:', err);
    res.status(500).json({ success: false, message: err.message });
  } finally {
    client.release();
  }
});

// Endpoint per la richiesta di disponibilità urgenti
router.get('/urgentbookings', authenticateToken, async (req, res) => {
  try {
    // Scriviamo la query SQL per selezionare i medici con disponibilità future
    const query = ` 
      SELECT u.id, u.first_name, u.last_name, a.available_date, a.start_time, a.end_time
      FROM users u
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
        available_date: new Date(new Date(row.available_date).setDate(new Date(row.available_date).getDate() + 1))
        .toISOString()
        .split('T')[0],
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
      SELECT 1 FROM users WHERE id = $1 and (role = 1 or role = 2);
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
        u.address AS patient_address, 
        b.booking_date,
        b.start_time,
        b.end_time,
        b.symptom_description,
        b.accepted_booking,
        b.treatment 
      FROM bookings b
      JOIN users u ON b.patient_id = u.id
      WHERE b.doctor_id = $1 AND u.role = 0 -- Assicurati di filtrare solo i pazienti
      ORDER BY b.id DESC; -- Ordinamento basato sull'ID in ordine decrescente
    `, [doctorId]);

    // Formatta i risultati
    const formattedBookings = result.rows.map(row => ({
      bookingId: row.booking_id,
      patientFirstName: row.patient_first_name,
      patientLastName: row.patient_last_name,
      patientAddress: row.patient_address, // Nuovo campo incluso nel risultato
      bookingDate: new Date(row.booking_date).toISOString().split('T')[0], // yyyy-mm-dd
      startTime: row.start_time.slice(0, 5), // HH:MM
      endTime: row.end_time.slice(0, 5),
      symptomDescription: row.symptom_description,
      acceptedBooking: row.accepted_booking,
      treatment: row.treatment // Nuovo campo aggiunto al risultato formattato
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
      SELECT 1 FROM users WHERE id = $1 and (role = 0);
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
      JOIN users u ON b.doctor_id = u.id
      WHERE b.patient_id = $1 AND (u.role = 1 OR u.role = 2) -- Assicurati di filtrare solo i medici
      ORDER BY b.id DESC; -- Ordinamento basato sull'ID in ordine decrescente
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
router.put('/bookings/accept/:id', authenticateToken, async (req, res) => {
  const bookingId = req.params.id;
  const { note } = req.body;
  const doctorId = req.user.id; // Get doctor ID from authenticated user

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Get booking details first
    const bookingQuery = await client.query(`
      SELECT 
        b.*,
        p.first_name as patient_first_name,
        p.last_name as patient_last_name,
        d.first_name as doctor_first_name,
        d.last_name as doctor_last_name
      FROM bookings b
      JOIN users p ON b.patient_id = p.id
      JOIN users d ON b.doctor_id = d.id
      WHERE b.id = $1 AND b.doctor_id = $2
    `, [bookingId, doctorId]);

    if (bookingQuery.rowCount === 0) {
      throw new Error('Prenotazione non trovata o non autorizzata.');
    }

    const booking = bookingQuery.rows[0];

    // Check if booking is already accepted
    if (booking.accepted_booking) {
      throw new Error('La prenotazione è già stata accettata.');
    }

    // Update booking with accepted status and note
    await client.query(`
      UPDATE bookings 
      SET accepted_booking = true, note = $1 
      WHERE id = $2
    `, [note, bookingId]);

    // Create notification for patient using the utility function
    const notificationMessage = `La tua prenotazione del ${new Date(booking.booking_date).toLocaleDateString('it-IT')} alle ${booking.start_time.slice(0, 5)}-${booking.end_time.slice(0, 5)} con il Dr. ${booking.doctor_first_name} ${booking.doctor_last_name} è stata accettata.${note ? ` Nota: ${note}` : ''}`;
    
    await createNotification(
      booking.patient_id,
      'booking_accepted',
      'Prenotazione Accettata',
      notificationMessage,
      client
    );

    await client.query('COMMIT');

    res.json({ 
      success: true, 
      message: 'Prenotazione accettata con successo.' 
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Errore nell\'accettazione della prenotazione:', err);
    res.status(400).json({ 
      success: false, 
      message: err.message 
    });
  } finally {
    client.release();
  }
});

// Doctor delete booking endpoint
// Doctor delete booking endpoint (with 1-hour rule and refund)
router.delete('/doctor/bookings/:id', authenticateToken, async (req, res) => {
  const bookingId = req.params.id;
  const doctorId = req.user.id;
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // Get booking details and verify doctor ownership
    const bookingQuery = await client.query(`
      SELECT 
        b.*,
        p.first_name as patient_first_name,
        p.last_name as patient_last_name
      FROM bookings b
      JOIN users p ON b.patient_id = p.id
      WHERE b.id = $1 AND b.doctor_id = $2
    `, [bookingId, doctorId]);

    if (bookingQuery.rowCount === 0) {
      throw new Error('Prenotazione non trovata o non autorizzata.');
    }

    const booking = bookingQuery.rows[0];
    
    // Check if booking is within 1 hour (same rule as patients)
    const bookingDateTime = new Date(`${booking.booking_date}T${booking.start_time}`);
    const now = new Date();
    const timeDifference = bookingDateTime.getTime() - now.getTime();
    const oneHourInMs = 60 * 60 * 1000;

    if (timeDifference <= oneHourInMs && timeDifference > 0) {
      throw new Error('Non è possibile cancellare la prenotazione. Manca meno di un\'ora all\'appuntamento.');
    }

    // Process refund if payment was made
    let refundProcessed = false;
    if (booking.payment_intent_id) {
      try {
        const refund = await stripe.refunds.create({
          payment_intent: booking.payment_intent_id,
          reason: 'requested_by_customer'
        });
        
        if (refund.status === 'succeeded' || refund.status === 'pending') {
          refundProcessed = true;
          console.log('Refund processed successfully by doctor:', refund.id);
        } else {
          throw new Error(`Refund failed with status: ${refund.status}`);
        }
      } catch (refundError) {
        console.error('Refund error:', refundError);
        throw new Error('Impossibile processare il rimborso. La prenotazione non può essere cancellata. Contatta il supporto.');
      }
    }

    // Restore availability slot
    const bookingDate = new Date(booking.booking_date).toISOString().split('T')[0];
    
    const existingAvailability = await client.query(`
      SELECT * FROM availability
      WHERE user_id = $1 AND available_date = $2 
      AND start_time = $3 AND end_time = $4
    `, [booking.doctor_id, bookingDate, booking.start_time, booking.end_time]);

    if (existingAvailability.rowCount > 0) {
      await client.query(`
        UPDATE availability
        SET max_patients = max_patients + 1
        WHERE user_id = $1 AND available_date = $2 
        AND start_time = $3 AND end_time = $4
      `, [booking.doctor_id, bookingDate, booking.start_time, booking.end_time]);
    } else {
      await client.query(`
        INSERT INTO availability (user_id, available_date, start_time, end_time, max_patients)
        VALUES ($1, $2, $3, $4, 1)
      `, [booking.doctor_id, bookingDate, booking.start_time, booking.end_time]);
    }

    // Delete the booking
    await client.query('DELETE FROM bookings WHERE id = $1', [bookingId]);

    // Notify patient about cancellation
    const notificationMessage = `La tua prenotazione del ${new Date(booking.booking_date).toLocaleDateString('it-IT')} alle ${booking.start_time.slice(0, 5)}-${booking.end_time.slice(0, 5)} è stata cancellata dal medico.${refundProcessed ? ' Il rimborso è stato processato.' : ''}`;
    
    await createNotification(
      booking.patient_id,
      'booking_cancelled',
      'Prenotazione Cancellata dal Medico',
      notificationMessage,
      client
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Prenotazione cancellata con successo.',
      refundProcessed: refundProcessed,
      refundAmount: booking.payment_intent_id ? 'Rimborso processato' : 'Nessun pagamento da rimborsare'
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Errore durante la cancellazione del dottore:', err);
    res.status(400).json({ 
      success: false, 
      message: err.message 
    });
  } finally {
    client.release();
  }
});

// Endpoint for deleting a booking with refund and doctor notification
router.delete('/bookings/delete/:id', authenticateToken, async (req, res) => {
  const bookingId = req.params.id;
  const patientId = req.user.id; // Get patient ID from authenticated user
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // 1. Get booking details and verify ownership
    const bookingQuery = await client.query(`
      SELECT 
        b.*,
        u.first_name as doctor_first_name,
        u.last_name as doctor_last_name,
        u.email as doctor_email
      FROM bookings b
      JOIN users u ON b.doctor_id = u.id
      WHERE b.id = $1 AND b.patient_id = $2
    `, [bookingId, patientId]);

    if (bookingQuery.rowCount === 0) {
      throw new Error('Prenotazione non trovata o non autorizzata.');
    }

    const booking = bookingQuery.rows[0];
    
    // 2. Check if booking is within 1 hour
    const bookingDateTime = new Date(`${booking.booking_date}T${booking.start_time}`);
    const now = new Date();
    const timeDifference = bookingDateTime.getTime() - now.getTime();
    const oneHourInMs = 60 * 60 * 1000;

    if (timeDifference <= oneHourInMs && timeDifference > 0) {
      throw new Error('Non è possibile cancellare la prenotazione. Manca meno di un\'ora all\'appuntamento.');
    }

    // 3. Process refund if payment was made
    let refundProcessed = false;
    if (booking.payment_intent_id) {
      try {
        const refund = await stripe.refunds.create({
          payment_intent: booking.payment_intent_id,
          reason: 'requested_by_customer'
        });
        
        if (refund.status === 'succeeded' || refund.status === 'pending') {
          refundProcessed = true;
          console.log('Refund processed successfully:', refund.id);
        } else {
          throw new Error(`Refund failed with status: ${refund.status}`);
        }
      } catch (refundError) {
        console.error('Refund error:', refundError);
        throw new Error('Impossibile processare il rimborso. La prenotazione non può essere cancellata. Contatta il supporto.');
      }
    }

    // 4. Restore availability slot
    const bookingDate = new Date(booking.booking_date).toISOString().split('T')[0];
    
    // Check if availability slot exists
    const existingAvailability = await client.query(`
      SELECT * FROM availability
      WHERE user_id = $1 AND available_date = $2 
      AND start_time = $3 AND end_time = $4
    `, [booking.doctor_id, bookingDate, booking.start_time, booking.end_time]);

    if (existingAvailability.rowCount > 0) {
      // Increment max_patients
      await client.query(`
        UPDATE availability
        SET max_patients = max_patients + 1
        WHERE user_id = $1 AND available_date = $2 
        AND start_time = $3 AND end_time = $4
      `, [booking.doctor_id, bookingDate, booking.start_time, booking.end_time]);
    } else {
      // Create new availability slot
      await client.query(`
        INSERT INTO availability (user_id, available_date, start_time, end_time, max_patients)
        VALUES ($1, $2, $3, $4, 1)
      `, [booking.doctor_id, bookingDate, booking.start_time, booking.end_time]);
    }

    // 5. Delete the booking
    await client.query('DELETE FROM bookings WHERE id = $1', [bookingId]);

    // 6. Create notification for doctor using the utility function
    const notificationMessage = `La prenotazione del ${new Date(booking.booking_date).toLocaleDateString('it-IT')} alle ${booking.start_time.slice(0, 5)}-${booking.end_time.slice(0, 5)} è stata cancellata dal paziente.`;
    
    await createNotification(
      booking.doctor_id,
      'booking_cancelled',
      'Prenotazione Cancellata',
      notificationMessage,
      client
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Prenotazione cancellata con successo.',
      refundProcessed: refundProcessed,
      refundAmount: booking.payment_intent_id ? 'Importo rimborsato' : 'Nessun pagamento da rimborsare'
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Errore durante la cancellazione della prenotazione:', err);
    res.status(400).json({ 
      success: false, 
      message: err.message 
    });
  } finally {
    client.release();
  }
});

module.exports = router;