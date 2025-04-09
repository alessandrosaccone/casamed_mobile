// routes/payments.js
const express = require('express');
const router = express.Router();
const Stripe = require('stripe');
const stripe = Stripe('sk_test_51RBewF4IOwwF31fGuJtENyMlKdSCwh6bmWzllqTz9iKuOev3T2jf8ectenKaxOhafDZVBF3pX9Y7Fd7OH2Fh2dUU00fFvvXvmL'); // ⚠️ Usa la tua secret key di Stripe

// POST /payments/create-payment-intent
router.post('/create-payment-intent', async (req, res) => {
  const { amount, currency } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount, // In centesimi! es: 1000 = €10.00
      currency, // es: 'eur'
      payment_method_types: ['card'],
    });

    res.send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error('Errore Stripe:', error);
    res.status(500).send({ error: error.message });
  }
});

module.exports = router;
