import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_page.dart';

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
  final TextEditingController _treatmentController = TextEditingController();

  void _validateAndProceed() {
    if (_symptomsController.text.isEmpty || _treatmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi prima di procedere.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          date: widget.date,
          startTime: widget.startTime,
          endTime: widget.endTime,
          doctorId: widget.doctorId,
          userId: widget.userId,
          token: widget.token,
          symptomDescription: _symptomsController.text,
          treatment: _treatmentController.text,
        ),
      ),
    );
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
              controller: _treatmentController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Descrivi la cura o i farmaci',
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _validateAndProceed,
                child: const Text('Paga la prenotazione'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
