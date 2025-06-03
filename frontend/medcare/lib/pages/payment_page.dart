import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
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

  // Funzione per formattare la data correttamente
  String _formatDisplayDate(String dateString) {
    try {
      // Parse la data come locale invece che UTC
      DateTime date;
      if (dateString.contains('T')) {
        // Se la data contiene 'T', è in formato ISO
        date = DateTime.parse(dateString).toLocal();
      } else {
        // Se è solo la data (YYYY-MM-DD), trattala come locale
        final parts = dateString.split('-');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[0]), // anno
            int.parse(parts[1]), // mese
            int.parse(parts[2]), // giorno
          );
        } else {
          date = DateTime.parse(dateString);
        }
      }

      // Formatta la data in italiano
      final months = [
        'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
        'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
      ];

      final weekdays = [
        'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'
      ];

      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      print('Errore nel parsing della data: $e');
      return dateString; // Fallback alla stringa originale
    }
  }

  // Funzione per compensare il problema UTC nel backend
  String _adjustDateForBackend(String dateString) {
    try {
      // Parse la data come locale
      DateTime date;
      if (dateString.contains('T')) {
        date = DateTime.parse(dateString).toLocal();
      } else {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[0]), // anno
            int.parse(parts[1]), // mese
            int.parse(parts[2]), // giorno
            12, // Aggiungi mezzogiorno per evitare problemi di fuso orario
          );
        } else {
          date = DateTime.parse(dateString);
        }
      }

      // Formatta in formato ISO ma con orario di mezzogiorno per evitare shift UTC
      return date.toIso8601String();
    } catch (e) {
      print('Errore nel parsing della data: $e');
      return dateString;
    }
  }

  // Metodo per verificare la disponibilità prima del pagamento
  Future<bool> _verifyAvailability() async {
    final url = Uri.parse('http://10.0.2.2:3000/bookings/verify');

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
          'bookingDate': _adjustDateForBackend(widget.date), // <-- FIX QUI
          'startTime': widget.startTime,
          'endTime': widget.endTime,
          'symptomDescription': widget.symptomDescription,
          'treatment': widget.treatment,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        print('Errore disponibilità: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (error) {
      print('Errore di connessione durante la verifica: $error');
      return false;
    }
  }

  // Metodo principale per gestire il pagamento e la prenotazione
  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool availabilityCheck = await _verifyAvailability();
      if (!availabilityCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disponibilità non più presente o errore nella verifica'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. Crea payment intent con i dati della booking
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/payments/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 1000, // 10€ in centesimi
          'currency': 'eur',
          'bookingData': {
            'doctorId': widget.doctorId,
            'patientId': widget.userId,
            'bookingDate': _adjustDateForBackend(widget.date), // <-- FIX QUI
            'startTime': widget.startTime,
            'endTime': widget.endTime,
            'symptomDescription': widget.symptomDescription,
            'treatment': widget.treatment,
          }
        }),
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella creazione del pagamento: ${response.body}')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final jsonResponse = jsonDecode(response.body);
      final clientSecret = jsonResponse['clientSecret'];
      final paymentIntentId = jsonResponse['paymentIntentId'];

      // 3. Mostra il payment sheet di Stripe
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'MedCare - Dr. ${widget.doctorId}',
          style: ThemeMode.light,
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      // 4. Se il pagamento è andato a buon fine, conferma e crea la booking
      final confirmResponse = await http.post(
        Uri.parse('http://10.0.2.2:3000/payments/confirm-payment-and-booking'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          'bookingData': {
            'doctorId': widget.doctorId,
            'patientId': widget.userId,
            'bookingDate': _adjustDateForBackend(widget.date), // <-- FIX QUI
            'startTime': widget.startTime,
            'endTime': widget.endTime,
            'symptomDescription': widget.symptomDescription,
            'treatment': widget.treatment,
          }
        }),
      );

      if (confirmResponse.statusCode == 200) {
        final confirmData = jsonDecode(confirmResponse.body);
        if (confirmData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pagamento e prenotazione completati con successo!'),
              backgroundColor: Colors.green,
            ),
          );

          // Naviga alla pagina del profilo
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => ProfilePage(
                    userId: widget.userId,
                    token: widget.token
                )
            ),
                (Route<dynamic> route) => false,
          );
        } else {
          throw Exception(confirmData['message'] ?? 'Errore nella conferma');
        }
      } else {
        final errorData = jsonDecode(confirmResponse.body);
        throw Exception(errorData['message'] ?? 'Errore del server');
      }

    } on stripe.StripeException catch (e) {
      print('Errore Stripe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel pagamento: ${e.error.localizedMessage ?? e.error.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Errore generale: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il processo: $e'),
          backgroundColor: Colors.red,
        ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Conferma Pagamento'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icona
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.medical_services_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Riepilogo Prenotazione',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Controlla i dettagli prima di procedere',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Card dettagli prenotazione
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Dettagli Appuntamento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow('Medico', 'ID: ${widget.doctorId}', Icons.person),
                      _buildInfoRow('Paziente', 'ID: ${widget.userId}', Icons.person_outline),
                      _buildInfoRow('Data', _formatDisplayDate(widget.date), Icons.calendar_today),
                      _buildInfoRow('Orario', '${widget.startTime} - ${widget.endTime}', Icons.access_time),
                      _buildInfoRow('Sintomi', widget.symptomDescription, Icons.description),
                      _buildInfoRow('Trattamento', widget.treatment, Icons.medical_information),

                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.euro, color: Colors.green[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Totale da pagare:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '10€',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info sicurezza
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pagamento sicuro gestito da Stripe. La prenotazione sarà confermata solo dopo il pagamento riuscito.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bottone pagamento
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isLoading
                    ? Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Elaborazione in corso...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : ElevatedButton(
                  onPressed: _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: Colors.blue.withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Procedi al Pagamento • 10€',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}