const express = require('express');
const router = express.Router();
const Stripe = require('stripe');
const pool = require('./db'); // Assicurati di importare la connessione al database
const authenticateToken = require('./authMiddleware'); // Middleware di autenticazione
const stripe = Stripe('sk_test_51RBewF4IOwwF31fGuJtENyMlKdSCwh6bmWzllqTz9iKuOev3T2jf8ectenKaxOhafDZVBF3pX9Y7Fd7OH2Fh2dUU00fFvvXvmL'); // ⚠️ Usa la tua secret key di Stripe

// POST /payments/create-payment-intent
router.post('/create-payment-intent', async (req, res) => {
  const { amount, currency, bookingData } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount, // In centesimi! es: 50 = €0.50
      currency, // es: 'eur'
      payment_method_types: ['card'],
      metadata: {
        // Salva i dati della prenotazione nei metadata per sicurezza
        doctorId: bookingData.doctorId.toString(),
        patientId: bookingData.patientId.toString(),
        bookingDate: bookingData.bookingDate,
        startTime: bookingData.startTime,
        endTime: bookingData.endTime,
        symptomDescription: bookingData.symptomDescription.substring(0, 500), // Stripe ha limiti sui metadata
        treatment: bookingData.treatment.substring(0, 500)
      }
    });

    res.send({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id
    });
  } catch (error) {
    console.error('Errore Stripe:', error);
    res.status(500).send({ error: error.message });
  }
});

// POST /payments/confirm-payment-and-booking - Transazione atomica
router.post('/confirm-payment-and-booking', authenticateToken, async (req, res) => {
  const { paymentIntentId, bookingData } = req.body;
  const { doctorId, patientId, bookingDate, startTime, endTime, symptomDescription, treatment } = bookingData;
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // 1. Verifica che il pagamento sia andato a buon fine
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    if (paymentIntent.status !== 'succeeded') {
      throw new Error('Pagamento non completato o non riuscito');
    }

    // 2. Controllo finale disponibilità dentro la transazione
    const date = (() => {
      const d = new Date(bookingDate);
      // Usa il fuso orario locale invece di UTC
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    })();
    
    const finalAvailabilityCheck = await client.query(`
      SELECT * FROM availability
      WHERE user_id = $1 AND available_date = $2 
      AND start_time = $3 AND end_time = $4 AND max_patients > 0
      FOR UPDATE;
    `, [doctorId, date, startTime, endTime]);

    if (finalAvailabilityCheck.rowCount === 0) {
      throw new Error('Disponibilità non più presente o esaurita.');
    }

    // 3. Controllo finale duplicati dentro la transazione
    const finalDuplicateCheck = await client.query(`
      SELECT 1 FROM bookings 
      WHERE doctor_id = $1 AND patient_id = $2 AND booking_date = $3 
      AND start_time = $4 AND end_time = $5;
    `, [doctorId, patientId, bookingDate, startTime, endTime]);

    if (finalDuplicateCheck.rowCount > 0) {
      throw new Error('La prenotazione esiste già per questo orario.');
    }

    // 4. Inserimento della prenotazione
    const bookingResult = await client.query(`
      INSERT INTO bookings (doctor_id, patient_id, booking_date, start_time, end_time, symptom_description, treatment, payment_intent_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *;
    `, [doctorId, patientId, bookingDate, startTime, endTime, symptomDescription, treatment, paymentIntentId]);

    // 5. Aggiornamento della disponibilità del medico
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

    // 6. Eliminazione della disponibilità se max_patients = 0
    await client.query(`
      DELETE FROM availability
      WHERE user_id = $1 AND available_date = $2 
      AND start_time = $3 AND end_time = $4 AND max_patients = 0;
    `, [doctorId, date, startTime, endTime]);

    await client.query('COMMIT');
    
    res.json({ 
      success: true, 
      message: 'Pagamento e prenotazione completati con successo',
      booking: bookingResult.rows[0],
      paymentStatus: paymentIntent.status
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Errore durante la transazione pagamento/prenotazione:', err);
    
    // Se il pagamento è andato a buon fine ma la prenotazione è fallita,
    // potresti voler gestire un refund automatico qui
    if (err.message.includes('Disponibilità') || err.message.includes('prenotazione esiste già')) {
      // Opzionale: refund automatico
      try {
        await stripe.refunds.create({
          payment_intent: paymentIntentId,
        });
        console.log('Refund automatico eseguito per PaymentIntent:', paymentIntentId);
      } catch (refundError) {
        console.error('Errore durante il refund automatico:', refundError);
      }
    }
    
    res.status(500).json({ 
      success: false, 
      message: err.message,
      shouldRefund: err.message.includes('Disponibilità') || err.message.includes('prenotazione esiste già')
    });
  } finally {
    client.release();
  }
});

// GET /payments/verify-payment/:paymentIntentId - Per verificare lo stato di un pagamento
router.get('/verify-payment/:paymentIntentId', authenticateToken, async (req, res) => {
  const { paymentIntentId } = req.params;
  
  try {
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    res.json({
      success: true,
      paymentStatus: paymentIntent.status,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      metadata: paymentIntent.metadata
    });
  } catch (error) {
    console.error('Errore nella verifica del pagamento:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;