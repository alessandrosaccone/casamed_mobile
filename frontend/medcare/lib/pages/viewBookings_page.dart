import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'accept_booking_page.dart';
import 'dart:convert';

class ViewBookingsPage extends StatefulWidget {
  final int userId;
  final String token;

  const ViewBookingsPage({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _ViewBookingsPageState createState() => _ViewBookingsPageState();
}

class _ViewBookingsPageState extends State<ViewBookingsPage> {
  List<dynamic> bookings = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    const url = 'http://10.0.2.2:3000/doctor/bookings'; // Sostituisci con l'URL corretto
    final token = widget.token; // Usa il token passato tramite il costruttore

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prenotazioni'),
      ),
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
        child: Text('Nessuna prenotazione trovata.'),
      )
          : ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          print(booking);
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AcceptBookingPage(
                          bookingId: booking["bookingId"],
                          token: widget.token,
                        ),
                  ),
                );
              },
              child: ListTile(
                title: Text(
                  'Paziente: ${booking['patientFirstName']} ${booking['patientLastName']}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data: ${booking['bookingDate']}'),
                    Text(
                        'Orario: ${booking['startTime']} - ${booking['endTime']}'),
                    Text('Sintomi: ${booking['symptomDescription']}'),
                  ],
                ),
                trailing: Icon(
                  booking['acceptedBooking'] == true
                      ? Icons.check_circle
                      : Icons.pending,
                  color: booking['acceptedBooking'] == true
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}