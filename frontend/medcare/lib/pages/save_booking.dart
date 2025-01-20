import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SaveBookingPage extends StatefulWidget {
  final int doctorId;
  final int userId;
  final String token;
  final String date;
  final String startTime;
  final String endTime;

  const SaveBookingPage({
    Key? key,
    required this.doctorId,
    required this.userId,
    required this.token,
    required this.date,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  _SaveBookingPageState createState() => _SaveBookingPageState();
}

class _SaveBookingPageState extends State<SaveBookingPage> {
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _treatmentController = TextEditingController(); // Controller per la cura

  Future<void> _createBooking() async {
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
          'symptomDescription': _symptomsController.text, // Sintomi
          'treatment': _treatmentController.text, // Cura o farmaci
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prenotazione creata con successo!')),
        );
        Navigator.pop(context); // Torna alla pagina precedente
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore durante la creazione della prenotazione: ${response.body}',
            ),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore di connessione.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salva Prenotazione')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inserisci i tuoi sintomi:'),
            const SizedBox(height: 8.0),
            TextField(
              controller: _symptomsController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Descrivi i tuoi sintomi',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Inserisci la cura o i farmaci che stai seguendo:'),
            const SizedBox(height: 8.0),
            TextField(
              controller: _treatmentController, // Campo per la cura
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Descrivi la cura o i farmaci',
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _createBooking, // Usa il metodo _createBooking
                child: const Text('Salva Prenotazione'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}








