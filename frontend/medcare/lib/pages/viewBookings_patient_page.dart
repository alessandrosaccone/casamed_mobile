import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewBookingsPatientPage extends StatefulWidget {
  final int userId;
  final String token;

  const ViewBookingsPatientPage({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _ViewBookingsPatientPageState createState() => _ViewBookingsPatientPageState();
}

class _ViewBookingsPatientPageState extends State<ViewBookingsPatientPage> {
  List<dynamic> bookings = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    const url = 'http://10.0.2.2:3000/patient/bookings';
    final token = widget.token;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            bookings = data['bookings'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Errore sconosciuto';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Errore del server: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Errore di connessione: $e';
        isLoading = false;
      });
    }
  }

  Future<void> deleteBooking(int bookingId, int index) async {
    // Get booking details to check timing
    final booking = bookings[index];
    final bookingDate = booking['bookingDate'];
    final startTime = booking['startTime'];

    // Check if booking is within 1 hour
    try {
      final bookingDateTime = DateTime.parse('$bookingDate $startTime:00');
      final now = DateTime.now();
      final difference = bookingDateTime.difference(now).inMinutes;

      if (difference <= 60 && difference > 0) {
        _showErrorDialog('Non è possibile cancellare la prenotazione. Manca meno di un\'ora all\'appuntamento.');
        return;
      }
    } catch (e) {
      // Continue with deletion if date parsing fails
    }

    // Show confirmation dialog
    bool? confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    // Show loading indicator
    _showLoadingDialog();

    final url = 'http://10.0.2.2:3000/bookings/delete/$bookingId';
    final token = widget.token;

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Hide loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Show success message
          String message = 'Prenotazione cancellata con successo.';
          if (data['refundProcessed'] == true) {
            message += '\n${data['refundAmount']}';
          }

          _showSuccessDialog(message);

          // Remove booking from list
          setState(() {
            bookings.removeAt(index);
          });
        } else {
          _showErrorDialog(data['message'] ?? 'Errore durante la cancellazione');
        }
      } else {
        _showErrorDialog('Errore del server: ${response.statusCode}');
      }
    } catch (e) {
      // Hide loading dialog if still showing
      Navigator.of(context).pop();
      _showErrorDialog('Errore di connessione: $e');
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Cancellazione'),
          content: const Text(
            'Sei sicuro di voler cancellare questa prenotazione?\n\n'
                'Il medico verrà notificato della cancellazione e, se hai effettuato un pagamento, riceverai un rimborso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancella Prenotazione'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Cancellazione in corso..."),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Successo'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Errore'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  bool _canCancelBooking(dynamic booking) {
    try {
      final bookingDate = booking['bookingDate'];
      final startTime = booking['startTime'];
      final bookingDateTime = DateTime.parse('$bookingDate $startTime:00');
      final now = DateTime.now();
      final difference = bookingDateTime.difference(now).inMinutes;

      // Can cancel if more than 1 hour away or if it's in the past
      return difference > 60 || difference < 0;
    } catch (e) {
      // If date parsing fails, allow cancellation
      return true;
    }
  }

  Color _getStatusColor(dynamic booking) {
    if (!_canCancelBooking(booking)) {
      return Colors.grey; // Too close to cancel
    }
    return booking['acceptedBooking'] == true ? Colors.green : Colors.orange;
  }

  String _getStatusText(dynamic booking) {
    if (!_canCancelBooking(booking)) {
      return 'Non cancellabile';
    }
    return booking['acceptedBooking'] == true ? 'Accettata' : 'In attesa';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : bookings.isEmpty
          ? const Center(
        child: Text('Non hai prenotazioni fatte.'),
      )
          : ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final canCancel = _canCancelBooking(booking);

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(
                'Medico: ${booking['doctorFirstName']} ${booking['doctorLastName']}',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data: ${booking['bookingDate']}'),
                  Text(
                      'Orario: ${booking['startTime']} - ${booking['endTime']}'),
                  Text('Sintomi: ${booking['symptomDescription']}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        booking['acceptedBooking'] == true
                            ? Icons.check_circle
                            : Icons.pending,
                        color: _getStatusColor(booking),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(booking),
                        style: TextStyle(
                          color: _getStatusColor(booking),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: canCancel
                  ? IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () => deleteBooking(
                  booking['bookingId'],
                  index,
                ),
                tooltip: 'Cancella prenotazione',
              )
                  : const Icon(
                Icons.block,
                color: Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}