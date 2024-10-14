import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Import for JSON encoding

class CalendarPage extends StatefulWidget {
  final int userId; // Add the User ID parameter
  final String token; // Add the Token parameter

  // Constructor to accept userId and token
  CalendarPage({required this.userId, required this.token});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Per memorizzare le date selezionate (disponibilità settimanale)
  Set<DateTime> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleziona Disponibilità')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 10, 16),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _selectedDays.contains(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;

                if (_selectedDays.contains(selectedDay)) {
                  _selectedDays.remove(selectedDay); // Deseleziona la data
                } else {
                  _selectedDays.add(selectedDay); // Aggiungi la data
                }
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          ElevatedButton(
            onPressed: _saveAvailability,
            child: Text('Salva Disponibilità'),
          ),
        ],
      ),
    );
  }

  // Funzione per salvare la disponibilità e inviarla al backend
  Future<void> _saveAvailability() async {
    // Convert the selected dates to a list of ISO8601 strings
    List<String> selectedDates = _selectedDays.map((day) => day.toIso8601String()).toList();

    // URL to send the request (replace with your backend address)
    final url = Uri.parse('http://10.0.2.2:3000/calendar/${widget.userId}');

    try {
      // Sending POST request to save availability
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // Add token for authentication
        },
        body: jsonEncode({'availability': selectedDates}), // Convert selected dates to JSON
      );

      if (response.statusCode == 200) {
        print('Disponibilità salvata con successo!');
        // Show a confirmation message using SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Disponibilità salvata con successo!'))
        );
      } else {
        print('Errore durante il salvataggio: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante il salvataggio.'))
        );
      }
    } catch (e) {
      print('Errore nella richiesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Si è verificato un errore.'))
      );
    }
  }
}
