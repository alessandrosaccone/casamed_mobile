import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_services.dart';

class BookingPage extends StatefulWidget {
  final int doctorId;
  final String doctorName;
  final String token;

  const BookingPage({
    Key? key,
    required this.doctorId,
    required this.doctorName,
    required this.token,
  }) : super(key: key);

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late Future<List<Map<String, dynamic>>> _doctorAvailability;
  late Map<DateTime, List<String>> _events;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _events = {};
    _doctorAvailability = _loadDoctorAvailability();
  }

  // Funzione per normalizzare le date, togliendo la componente tempo
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<List<Map<String, dynamic>>> _loadDoctorAvailability() async {
    final availabilities = await ApiService(baseUrl: 'http://10.0.2.2:3000').getDoctorAvailability(widget.doctorId, widget.token);

    setState(() {
      // Popoliamo la mappa _events con le date e gli orari delle disponibilità
      for (var availability in availabilities) {
        DateTime fullDateTime = DateTime.parse(availability['date']).toLocal();
        DateTime date = _normalizeDate(fullDateTime);  // Normalizza la data

        String timeRange = '${availability['start_time']} - ${availability['end_time']}';

        if (_events.containsKey(date)) {
          _events[date]?.add(timeRange);  // Aggiunge l'orario se esistono già eventi per quella data
        } else {
          _events[date] = [timeRange];  // Crea una nuova entry per quella data
        }
      }
    });

    return availabilities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorName),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _doctorAvailability,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Qui mostriamo il calendario anche se non ci sono eventi
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 10, 16),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) {
                  // Anche se non ci sono eventi, restituiamo una lista vuota
                  return _events[_normalizeDate(day)] ?? [];
                },
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: _buildAvailabilityList(),
              ),
            ],
          );
        },
      ),
    );
  }

  // Funzione per mostrare la lista degli orari per il giorno selezionato
  Widget _buildAvailabilityList() {
    final events = _events[_normalizeDate(_selectedDay)] ?? [];

    if (events.isEmpty) {
      return const Center(child: Text('No availabilities on this day.'));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(events[index]),  // Mostra l'orario disponibile
        );
      },
    );
  }
}
