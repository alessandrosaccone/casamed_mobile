import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final int? doctorId;
  final int? userId;
  final String? token;

  const PaymentPage({
    Key? key,
    this.doctorId,
    this.userId,
    this.token,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Richiesta al backend per creare il PaymentIntent
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/payments/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 50, // 0.001 euro = 1 centesimo
          'currency': 'eur',
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      final clientSecret = jsonResponse['clientSecret'];

      // 2. Confermare il pagamento con Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Dr. ${widget.doctorId}', // o un nome fisso
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento effettuato con successo!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Errore pagamento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il pagamento: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riepilogo Prenotazione',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('ID Medico: ${widget.doctorId ?? "N/A"}'),
            Text('ID Utente: ${widget.userId ?? "N/A"}'),
            const SizedBox(height: 20),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _handlePayment,
                child: const Text('Paga Ora (0.001€)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
