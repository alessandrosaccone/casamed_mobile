import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http; // Importa il pacchetto http
import 'dart:convert'; // Import per la codifica in JSON
import '../services/api_services.dart';
import 'booking_page.dart'; // Importa la pagina BookingPage

class CalendarPage extends StatefulWidget {
  final int userId; // Aggiungi il parametro User ID
  final String token; // Aggiungi il parametro Token

  CalendarPage({required this.userId, required this.token});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Map<String, dynamic>> _availability = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> _events = {}; // Mappa per i giorni con eventi
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Variabili per memorizzare la selezione dell'orario
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Set per memorizzare i giorni selezionati
  Set<DateTime> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    _fetchAvailability(); // Load existing availability on page load
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }


  Future<void> _fetchAvailability() async {
    try {
      final apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');
      List<Map<String, dynamic>> availability =
      await apiService.getDoctorAvailability(widget.userId, widget.token);

      setState(() {
        _events.clear();
        for (var slot in availability) {
          DateTime date = _normalizeDate(DateTime.parse(slot['date']).toLocal());

          if (_events.containsKey(date)) {
            _events[date]?.add(slot); // Aggiungi evento esistente
          } else {
            _events[date] = [slot]; // Crea nuovo giorno con eventi
          }
        }
      });
    } catch (e) {
      print('Error fetching availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch availability.')),
      );
    }
  }


  // Funzione per navigare alla pagina di gestione delle disponibilità
  void _navigateToBookingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(
          doctorId: widget.userId,
          doctorName: 'Not useful',
          isDoctor:  true,
          userId: widget.userId,
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleziona Disponibilità'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 10, 16),
            focusedDay: _focusedDay,
            eventLoader: (day) {
              return _events[_normalizeDate(day)] ?? [];
            },
            selectedDayPredicate: (day) => _selectedDays.contains(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedDays.contains(selectedDay) ? _selectedDays.remove(selectedDay) : _selectedDays.add(selectedDay);
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          SizedBox(height: 20),
          _buildTimeSelector(),
          ElevatedButton(
            onPressed: _saveAvailability,
            child: Text('Salva Disponibilità'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _navigateToBookingPage,
            child: Text('Vai alla pagina per cancellare le disponibilità'),
          ),
        ],
      ),
    );
  }

  // Funzione per selezionare l'orario di inizio
  Future<void> _selectStartTime(BuildContext context) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      setState(() {
        _startTime = selectedTime;
      });
    }
  }

  // Funzione per selezionare l'orario di fine
  Future<void> _selectEndTime(BuildContext context) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      setState(() {
        _endTime = selectedTime;
      });
    }
  }

  // Funzione per costruire la parte dell'interfaccia che seleziona orari
  Widget _buildTimeSelector() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Orario di inizio: '),
            _startTime == null
                ? Text('Non selezionato')
                : Text('${_startTime!.hour}:${_startTime!.minute}'),
            TextButton(
              onPressed: () => _selectStartTime(context),
              child: Text('Seleziona Inizio'),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Orario di fine: '),
            _endTime == null
                ? Text('Non selezionato')
                : Text('${_endTime!.hour}:${_endTime!.minute}'),
            TextButton(
              onPressed: () => _selectEndTime(context),
              child: Text('Seleziona Fine'),
            ),
          ],
        ),
      ],
    );
  }

  // Funzione per salvare la disponibilità e inviarla al backend
  Future<void> _saveAvailability() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleziona un orario di inizio e fine')),
      );
      return;
    }

    // Converti i giorni selezionati e gli orari in una lista
    List<Map<String, dynamic>> availabilityData = _selectedDays.map((day) {
      return {
        'date': day.toIso8601String(),
        'start_time': '${_startTime!.hour}:${_startTime!.minute}',
        'end_time': '${_endTime!.hour}:${_endTime!.minute}',
      };
    }).toList();

    // URL per inviare la richiesta (sostituisci con l'indirizzo del tuo backend)
    final url = Uri.parse('http://10.0.2.2:3000/calendar/${widget.userId}');

    try {
      // Invio della richiesta POST per salvare la disponibilità
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // Token per l'autenticazione
        },
        body: jsonEncode({'availability': availabilityData}), // Dati in formato JSON
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disponibilità salvata con successo!')),
        );

        // Dopo aver salvato, ricarica la disponibilità aggiornata
        _fetchAvailability(); // Ricarica la disponibilità aggiornata

      } else {
        // Analizza il corpo della risposta per errori specifici
        final responseBody = jsonDecode(response.body);
        String errorMessage;

        if (responseBody.containsKey('message')) {
          errorMessage = responseBody['message'];
        } else if (responseBody.containsKey('errors')) {
          // Se ci sono errori di validazione, mostralo
          List<dynamic> errors = responseBody['errors'];
          errorMessage = errors.map((e) => e['msg']).join(', ');
        } else {
          errorMessage = 'Errore durante il salvataggio.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Errore nella richiesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Si è verificato un errore di rete.')),
      );
    }
  }
}
