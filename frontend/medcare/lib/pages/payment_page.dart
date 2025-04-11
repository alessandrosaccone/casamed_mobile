import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:medcare/pages/profile_page.dart';
import 'package:medcare/pages/viewBookings_patient_page.dart';
import 'dart:convert';
import 'discovery_page.dart';
import 'home_page.dart';

class PaymentPage extends StatefulWidget {
  final int doctorId;
  final int userId;
  final String token;
  final String date;
  final String startTime;
  final String endTime;
  final String symptomDescription;
  final String treatment;

  const PaymentPage({
    Key? key,
    required this.doctorId,
    required this.userId,
    required this.token,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.symptomDescription,
    required this.treatment,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;

  Future<bool> _createBooking() async {
    final url = Uri.parse('http://10.0.2.2:3000/bookings');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'doctorId': widget.doctorId,
          'patientId': widget.userId,
          'bookingDate': widget.date,
          'startTime': widget.startTime,
          'endTime': widget.endTime,
          'symptomDescription': widget.symptomDescription,
          'treatment': widget.treatment,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella creazione: ${response.body}')),
        );
        return false;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore di connessione.')),
      );
      return false;
    }
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool bookingSuccess = await _createBooking();
      if (!bookingSuccess) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/payments/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 50,
          'currency': 'eur',
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      final clientSecret = jsonResponse['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Dr. ${widget.doctorId}',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento effettuato con successo!')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ViewBookingsPatientPage(userId: widget.userId, token: widget.token)),
            (Route<dynamic> route) => false,
      );
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
            const Text('Riepilogo Prenotazione',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('ID Medico: ${widget.doctorId}'),
            Text('ID Utente: ${widget.userId}'),
            Text('Sintomi: ${widget.symptomDescription}'),
            Text('Trattamento: ${widget.treatment}'),
            const SizedBox(height: 20),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _handlePayment,
                child: const Text('Paga Ora (0.50€)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
