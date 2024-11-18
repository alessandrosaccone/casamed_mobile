import 'package:flutter/material.dart';
import '../services/api_services.dart';

class UrgentBookingPage extends StatefulWidget {
  final int doctorId;
  final String doctorName;
  final String token;
  final bool isDoctor;

  const UrgentBookingPage({
    Key? key,
    required this.doctorId,
    required this.doctorName,
    required this.token,
    required this.isDoctor,
  }) : super(key: key);

  @override
  _UrgentBookingPageState createState() => _UrgentBookingPageState();
}

class _UrgentBookingPageState extends State<UrgentBookingPage> {
  late Future<Map<String, dynamic>> _closestAvailability; // Variabile per la disponibilità urgente

  @override
  void initState() {
    super.initState();
    _closestAvailability = _loadUrgentBooking(); // Carica la disponibilità più urgente
  }

  // Funzione per ottenere la disponibilità urgente più vicina
  Future<Map<String, dynamic>> _loadUrgentBooking() async {
    try {
      final availability = await ApiService(baseUrl: 'http://10.0.2.2:3000')
          .getUrgentBooking(widget.doctorId, widget.token); // Chiamata al nuovo endpoint
      return availability;
    } catch (e) {
      throw Exception('Errore nel recuperare la disponibilità urgente: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorName),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _closestAvailability,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Se non ci sono disponibilità urgenti
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nessuna disponibilità urgente trovata.'));
          }

          final closestAvailability = snapshot.data!;

          return Center(
            child: ListTile(
              title: Text('Disponibilità più vicina:'),
              subtitle: Text('${closestAvailability['available_date']}'),
            ),
          );
        },
      ),
    );
  }
}









/*import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_services.dart';

class UrgentBookingPage extends StatefulWidget {
  final int doctorId;
  final String doctorName;
  final String token;
  final bool isDoctor;

  const UrgentBookingPage({
    Key? key,
    required this.doctorId,
    required this.doctorName,
    required this.token,
    required this.isDoctor,
  }) : super(key: key);

  @override
  _UrgentBookingPageState createState() => _UrgentBookingPageState();
}

class _UrgentBookingPageState extends State<UrgentBookingPage> {
  late Future<List<Map<String, dynamic>>> _doctorAvailability;
  late Map<DateTime, List<Map<String, dynamic>>> _events;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _events = {};
    _doctorAvailability = _loadDoctorAvailability();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<List<Map<String, dynamic>>> _loadDoctorAvailability() async {
    final availabilities = await ApiService(baseUrl: 'http://10.0.2.2:3000')
        .getDoctorAvailability(widget.doctorId, widget.token);

    setState(() {
      _events.clear();
      for (var availability in availabilities) {
        DateTime fullDateTime = DateTime.parse(availability['date']).toLocal();
        DateTime date = _normalizeDate(fullDateTime);
        String timeRange = '${availability['start_time']} - ${availability['end_time']}';

        if (_events.containsKey(date)) {
          _events[date]?.add({
            'timeRange': timeRange,
            'date': availability['date'],
            'start_time': availability['start_time'],
            'end_time': availability['end_time'],
          });
        } else {
          _events[date] = [
            {
              'timeRange': timeRange,
              'date': availability['date'],
              'start_time': availability['start_time'],
              'end_time': availability['end_time'],
            }
          ];
        }
      }
    });

    return availabilities;
  }

  // Funzione per trovare la disponibilità più vicina
  Map<String, dynamic>? _findClosestAvailability() {
    DateTime now = DateTime.now();
    Map<String, dynamic>? closest;
    Duration minDuration = Duration(days: 365); // inizialmente impostato su un valore alto

    _events.forEach((date, availabilities) {
      for (var availability in availabilities) {
        DateTime availabilityDate = DateTime.parse(availability['date']).toLocal();
        Duration difference = availabilityDate.difference(now);

        if (difference.isNegative) continue; // Ignora le date passate

        if (difference < minDuration) {
          minDuration = difference;
          closest = availability;
        }
      }
    });

    return closest;
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

          // Se l'utente è un paziente, mostra solo la disponibilità più vicina
          if (!widget.isDoctor) {
            final closestAvailability = _findClosestAvailability();
            if (closestAvailability == null) {
              return Center(child: Text('Nessuna disponibilità urgente trovata.'));
            }

            return Center(
              child: ListTile(
                title: Text('Disponibilità più vicina:'),
                subtitle: Text(closestAvailability['timeRange']),
              ),
            );
          }

          // Altrimenti, mostra tutte le disponibilità per il medico
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 10, 16),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => _events[_normalizeDate(day)] ?? [],
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

  Widget _buildAvailabilityList() {
    final dayEvents = _events[_normalizeDate(_selectedDay)] ?? [];

    if (dayEvents.isEmpty) {
      return const Center(child: Text('Nessuna disponibilità per questa giornata.'));
    }

    return ListView.builder(
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return ListTile(
          title: Text(event['timeRange']),
        );
      },
    );
  }
}*/